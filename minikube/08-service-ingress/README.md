# 📘 Kubernetesチュートリアル: **Deployment** + Service + Ingress（ECR版・CKAD対応）

>  **Why Deployment?**  
>  CKAD 本番・実務ともに *単発 Pod* ではなく **Deployment** が推奨。自己修復・ローリング更新・スケーリングといった本番運用要件を満たすためです。

---

## 📂 作業ディレクトリ構成（例）

```bash
~/dev/k8s-ckad/minikube/01.2-service/
├── deploy-ecr.yaml       # Deployment ひな形（kubectl create deployment で生成）
├── service.yaml          # Service ひな形（kubectl expose で生成）
├── ingress.yaml          # Ingress 手動作成
└── busybox-test.yaml     # busybox 検証用（kubectl run で生成）
```

> 💡 **YAML は出来る限り `kubectl create deployment / expose` で生成 → 最小編集** を徹底します。

---

## ✅ Step 1 — Deployment YAML を生成

```bash
# label を付与して Pod selector と揃える
kubectl create deployment nodejs-api \
  --image=986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5 \
  --replicas=1 \
  --dry-run=client -o yaml > deploy-ecr.yaml
```

**最小編集ポイント（3か所だけ）**
1. `spec.template.spec.containers[0].name` を `nodejs-api-container` に変更
2. `containerPort: 8000` を追記
3. `imagePullSecrets` に `ecr-registry-secret` を追加

---

## ✅ Step 2 — Deployment 作成（`--save-config` 推奨）

```bash
kubectl create -f deploy-ecr.yaml --save-config   # 初回のみ
# 以降は kubectl apply -f deploy-ecr.yaml で差分反映
```

---

## ✅ Step 3 — Service YAML を生成（Deployment の selector に合わせる）

```bash
kubectl expose deployment nodejs-api \
  --name=nodejs-api-service \
  --port=8000 --target-port=8000 \
  --type=NodePort \
  --dry-run=client -o yaml > service.yaml
```

> 任意で `nodePort: 30080` を追記。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nodejs-api-service
spec:
  selector:
    app: nodejs-api     # Deployment が自動で付けたラベル
  ports:
    - port: 8000
      targetPort: 8000
      nodePort: 30080   # 手動追加（任意）
  type: NodePort
```

```bash
kubectl apply -f service.yaml
```

---

## ✅ Step 4 — Ingress YAML を作成

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nodejs-api-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: nodejs-api-service
                port:
                  number: 8000
```

```bash
minikube addons enable ingress   # 1回だけ
kubectl apply -f ingress.yaml
```

---

## ✅ Step 5 — busybox テスト Pod 生成

```bash
kubectl run busybox-test --image=busybox \
  --command -- sh -c "while true; do sleep 3600; done" \
  --restart=Never --dry-run=client -o yaml > busybox-test.yaml
kubectl apply -f busybox-test.yaml
```

---

## 🔍 Step 6 — 内部疎通 (ClusterIP) を確認

```bash
kubectl wait --for=condition=available deployment/nodejs-api --timeout=60s
kubectl get endpoints nodejs-api-service -o wide

POD=$(kubectl get pod -l app=busybox-test -o jsonpath='{.items[0].metadata.name}')
kubectl exec "$POD" -- wget -qO- http://nodejs-api-service:8000/ || echo "❌ 接続失敗"
```

---

## 🌐 Step 7 — NodePort / Ingress で外部アクセス

```bash
curl http://<EC2 PublicIP>:30080/   # NodePort
MINIKUBE_IP=$(minikube ip)
curl http://$MINIKUBE_IP/api/      # Ingress
```

---

## 📄 完成版 YAML 集

> 下記の内容をそのままファイル化すれば動作します。

### 1. deploy-ecr.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nodejs-api
  template:
    metadata:
      labels:
        app: nodejs-api
    spec:
      imagePullSecrets:
        - name: ecr-registry-secret
      containers:
        - name: nodejs-api-container
          image: 986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5
          ports:
            - containerPort: 8000
```

### 2. service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nodejs-api-service
spec:
  selector:
    app: nodejs-api
  ports:
    - port: 8000
      targetPort: 8000
      nodePort: 30080   # 任意で変更可（30000-32767）
  type: NodePort
```

### 3. ingress.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nodejs-api-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: nodejs-api-service
                port:
                  number: 8000
```

### 4. busybox-test.yaml  (検証用 Pod)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox-test
  labels:
    app: busybox-test
spec:
  containers:
    - name: busybox
      image: busybox
      command: ["sh", "-c", "while true; do sleep 3600; done"]
  restartPolicy: Never
```

---

## ✅ まとめ

| 学習目標 | コマンド | ポイント |
|----------|----------|----------|
| **Deployment** ひな形作成 | `kubectl create deployment --dry-run` | 本番運用前提 |
| Service ひな形 | `kubectl expose deployment` | selector 自動一致 |
| Ingress | 手動 YAML | `/api` → Service |
| 内部疎通 | busybox Pod | Endpoints 確認 |
| 外部疎通 | NodePort / Ingress | SG 開放 & IP 確認 |

Deployment ベースに置き換えたことで、CKAD 本番でもそのまま使える構成になりました！

