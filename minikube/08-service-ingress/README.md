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
kubectl run nodejs-api-pod \
  --image=986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5 \
  --port=8000 --dry-run=client -o yaml > pod-ecr.yaml
```

その後、以下の修正を加えます：
- `metadata.labels` を `app: nodejs-api` に変更
- コンテナ名を `nodejs-api-container` に変更
- `containerPort: 8000` を追記
- `imagePullSecrets` を追加して ECR シークレットを指定

---

## ✅ Step 2: ServiceのYAML生成（kubectl expose）

```bash
kubectl expose pod nodejs-api-pod \
  --name=nodejs-api-service --port=8000 --target-port=8000 \
  --type=NodePort --dry-run=client -o yaml > service.yaml
```

必要に応じて `nodePort: 8000` を手動で指定します（ポート開放済みのため）。

---

## ✅ Step 3: IngressのYAML手動作成

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

## ✅ Step 4: busybox Pod で ClusterIP 接続検証用 YAML 生成

```bash
kubectl run busybox-test --image=busybox \
  --command -- sh -c 'while true; do sleep 3600; done' \
  --restart=Always --dry-run=client -o yaml > busybox-test.yaml
```

---

## ✅ Step 5: リソースの作成

```bash
kubectl apply -f pod-ecr.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
kubectl apply -f busybox-test.yaml
```

---

## 🔍 Step 6: ClusterIP の接続検証

```bash
kubectl get svc nodejs-api-service
kubectl get endpoints nodejs-api-service
kubectl exec -it busybox-test -- wget -qO- http://nodejs-api-service:8000/
```

---

## 🌐 Step 7: NodePort で外部公開（EC2）

```bash
curl http://<EC2のパブリックIP>:8000/
```

※ Security Group でポート8000を開放しておく必要あり

---

## 🌐 Step 8: Ingress 経由のHTTPアクセス確認

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

🔥 ご希望であればこの続きで Deployment や HPA、ConfigMap 連携なども展開可能です！

