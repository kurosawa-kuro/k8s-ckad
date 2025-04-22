# 📘 Kubernetesチュートリアル: Pod + Service + Ingress（ECR版・CKAD対応）

このチュートリアルでは、AWS ECR 上の Node.js API イメージを Minikube 環境で Pod として起動し、
Service による内部・外部アクセスの公開、および Ingress による HTTP 経路制御までを CKAD 試験想定で実践します。

---

## 📂 作業ディレクトリ構成（例）

```bash
~/dev/k8s-ckad/minikube/01.2-service/
├── pod-ecr.yaml         # ECR連携済みPod定義（kubectl runで生成）
├── service.yaml         # ClusterIP + NodePort公開用Service（kubectl exposeで生成）
├── ingress.yaml         # /api パスでルーティングするIngress
└── busybox-test.yaml    # ClusterIP経由検証用Pod
```

---

## ✅ Step 1: PodのYAML生成（kubectl run）

```bash
kubectl run nodejs-api-pod --image=986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5 --port=8000 --dry-run=client -o yaml > pod-ecr.yaml
```

その後、以下の修正を加えます：
- `metadata.labels` を `app: nodejs-api` に変更
- コンテナ名を `nodejs-api-container` に変更
- `containerPort: 8000` を追記
- `imagePullSecrets` を追加して ECR シークレットを指定

```
apiVersion: v1
kind: Pod
metadata:
  name: nodejs-api-pod
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
  restartPolicy: Always
```

---

## ✅ Step 2: Podの作成（--save-configオプション付き）

```bash
# 初回作成時は--save-configオプションを使用
kubectl create -f pod-ecr.yaml --save-config

# または、直接作成してからYAMLを保存
kubectl create -f pod-ecr.yaml
kubectl get pod nodejs-api-pod -o yaml > pod-ecr.yaml
```

---

## ✅ Step 3: ServiceのYAML生成（kubectl expose）

```bash
kubectl expose pod nodejs-api-pod \
  --name=nodejs-api-service --port=8000 --target-port=8000 \
  --type=NodePort --dry-run=client -o yaml > service.yaml
```

必要に応じて `nodePort: 30080` を手動で指定します（NodePortの有効な範囲は30000-32767）。

```
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
      nodePort: 30080
  type: NodePort
```

---

## ✅ Step 4: Serviceの作成（--save-configオプション付き）

```bash
# 初回作成時は--save-configオプションを使用
kubectl create -f service.yaml --save-config

# または、直接作成してからYAMLを保存
kubectl create -f service.yaml
kubectl get service nodejs-api-service -o yaml > service.yaml
```

---

## ✅ Step 5: IngressのYAML手動作成

```yaml
ingress.yaml
```
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

---

## ✅ Step 6: Ingressの作成（--save-configオプション付き）

```bash
# 初回作成時は--save-configオプションを使用
kubectl create -f ingress.yaml --save-config

# または、直接作成してからYAMLを保存
kubectl create -f ingress.yaml
kubectl get ingress nodejs-api-ingress -o yaml > ingress.yaml
```

---

## ✅ Step 7: busybox Pod で ClusterIP 接続検証用 YAML 生成

```bash
# 方法1: Deploymentとして作成
kubectl create deployment busybox-test --image=busybox --dry-run=client -o yaml > busybox-test.yaml

# または方法2: Podとして直接作成
cat <<EOF > busybox-test.yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox-test
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sh", "-c", "while true; do sleep 3600; done"]
  restartPolicy: Always
EOF
```

---

## ✅ Step 8: busybox Podの作成（--save-configオプション付き）

```bash
# 初回作成時は--save-configオプションを使用
kubectl create -f busybox-test.yaml --save-config

# または、直接作成してからYAMLを保存
kubectl create -f busybox-test.yaml
kubectl get pod busybox-test -o yaml > busybox-test.yaml
```

---

## ✅ Step 9: busybox Podの再生成が必要な場合

```bash
# 既存のPodを削除
kubectl delete pod busybox-test

# 新しい設定で再作成
kubectl apply -f busybox-test.yaml
```

---

## 🔍 Step 10: ClusterIP の接続検証

```bash
kubectl get svc nodejs-api-service
kubectl get endpoints nodejs-api-service
kubectl exec -it busybox-test -- wget -qO- http://nodejs-api-service:8000/
```

---

## 🌐 Step 11: NodePort で外部公開（EC2）

```bash
curl http://<EC2のパブリックIP>:30080/
```

※ Security Group でポート30080を開放しておく必要あり

---

## 🌐 Step 12: Ingress 経由のHTTPアクセス確認

```bash
minikube addons enable ingress  # 一度だけ必要
minikube ip                     # → <MINIKUBE_IP> を取得
curl http://<MINIKUBE_IP>/api/
```

---

## ✅ まとめ

- Pod を ECR イメージから起動（`imagePullSecrets` 指定）
- `kubectl run` / `kubectl expose` による YAML 生成手順を採用
- Service (ClusterIP / NodePort) による安定ルーティング
- Ingress による外部HTTPアクセス集約制御
- `--save-config` オプションを使用してリソースの更新を可能に

🔥 ご希望であればこの続きで Deployment や HPA、ConfigMap 連携なども展開可能です！

