了解です！  
以下は、**ターゲットディレクトリを `~/dev/01-pod-basic-ingress/` に固定した構成**で整理した、Ingress付きnginx公開チュートリアル（EC2 + minikube対応）です👇

---

# 📘 Kubernetesチュートリアル: Pod + Ingressでnginxを外部公開  
📂 `~/dev/k8s-ckad/minikube/01-pod-basic-ingress/`（CKAD × EC2 + minikube）

---

## ✅ 0. minikube クラスター管理 (初回またはクリーンアップ時)

```bash
# 既存クラスターの削除（必要な場合）
minikube delete --profile ckad-cluster

# 新規クラスターの作成
minikube start --profile ckad-cluster

# クラスター状態の確認
minikube status -p ckad-cluster
kubectl cluster-info
```

---

## ✅ 1. ディレクトリ準備

```bash
mkdir -p ~/dev/k8s-ckad/minikube/01-pod-basic-ingress
cd ~/dev/k8s-ckad/minikube/01-pod-basic-ingress
```

---

## ✅ 2. nginx Deployment の作成

```bash
kubectl create deployment nginx-deploy --image=nginx:latest --dry-run=client -o yaml > nginx-deploy.yaml
```

修正後の内容（`nginx-deploy.yaml`）👇

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx-container
          image: nginx:latest
          ports:
            - containerPort: 80
```

適用：

```bash
kubectl apply -f nginx-deploy.yaml
```

---

## ✅ 3. ClusterIP Service の作成 (コマンドで生成)

```bash
kubectl expose deployment nginx-deploy \
  --name=nginx-service \
  --port=80 \
  --target-port=80 \
  --type=ClusterIP \
  --dry-run=client -o yaml > nginx-svc.yaml
```

生成された `nginx-svc.yaml` を確認（任意）

適用：

```bash
kubectl apply -f nginx-svc.yaml
```

---

## ✅ 4. Ingressリソース作成 (コマンドで生成)

```bash
kubectl create ingress nginx-ingress \
  --rule="/=nginx-service:80" \
  --path-type=Prefix \
  --dry-run=client -o yaml > nginx-ingress.yaml
```

生成された `nginx-ingress.yaml` を確認（任意）

適用：

```bash
kubectl apply -f nginx-ingress.yaml
```

---

## ✅ 5. Ingress Controller の有効化（クラスターごとに1度だけ）

**注意:** Ingress自体はCKAD試験範囲ですが、minikubeのIngressアドオンや外部アクセスは直接の試験範囲外です。ここではIngressリソースの作成と基本的な動作確認に焦点を当てます。

```bash
# プロファイルを指定してIngressを有効化
minikube addons enable ingress -p ckad-cluster
```

確認：

```bash
kubectl get pods -n ingress-nginx
```

--- 

## ✅ 6. Serviceへのアクセス確認 (kubectl port-forward)

Ingress経由ではなく、Serviceに直接ポートフォワードしてアクセスを確認します。

```bash
# 別ターミナル or tmux で実行 (フォアグラウンドで実行されます)
kubectl port-forward svc/nginx-service 8080:80
```

**注意:** このコマンドは実行したターミナルがアクティブな間のみ有効です。Ctrl+Cで停止します。

--- 

## ✅ 7. port-forward経由でのアクセス確認

上記 `port-forward` を実行しているターミナルとは **別のターミナル** で実行します。

```bash
# EC2インスタンス内からlocalhost:8080にアクセス
curl localhost:8080
```

→ nginx の Welcome画面が表示されればServiceは正常に動作しています 🎉

--- 

## ✅ 8. クリーンアップ

```bash
# port-forwardを実行しているターミナルで Ctrl+C を押して停止

# Kubernetesリソースの削除
kubectl delete -f nginx-ingress.yaml
kubectl delete -f nginx-svc.yaml
kubectl delete -f nginx-deploy.yaml

# minikube クラスターの削除（不要な場合）
minikube delete --profile ckad-cluster
```

---

## ✅ ファイル構成（完成時）

```bash
~/dev/k8s-ckad/minikube/01-pod-basic-ingress/
├── nginx-deploy.yaml
├── nginx-svc.yaml
└── nginx-ingress.yaml
```

---

## 🎯 CKAD学習ポイント

| スキル           | 内容                       |
|------------------|----------------------------|
| 試験対策         | Deployment, Service, Ingress のYAML構成とコマンド生成 |
| 基本動作確認     | `kubectl port-forward` を使ったServiceへのアクセス確認 |
| マニフェスト練習 | `kubectl create/expose --dry-run=client -o yaml` の反復練習 |

---

## 📝 注意事項

1. minikubeプロファイルの確認と指定
   ```bash
   # プロファイル一覧の確認
   minikube profile list
   
   # プロファイルの指定（例：ckad-cluster）
   minikube start --profile ckad-cluster
   minikube addons enable ingress -p ckad-cluster
   ```

2. プロファイルの切り替え
   ```bash
   # プロファイルの切り替え
   minikube profile ckad-cluster
   
   # 現在のプロファイルの確認
   minikube profile
   ```

3. アクセス方法
   - このチュートリアルでは `kubectl port-forward` を使用し、`localhost:8080` (EC2インスタンス内) でアクセス確認します。
   - Ingress経由の外部アクセスは `minikube tunnel` が必要となり、CKAD試験の直接的な範囲外です。

4. トラブルシューティング
   - `port-forward` がエラーになる場合: Service (`nginx-service`) や Deployment (`nginx-deploy`) が正しく起動しているか確認 (`kubectl get svc,deploy,pods`)。
   - Ingressコントローラーが起動しない場合: `kubectl describe pod -n ingress-nginx`で詳細を確認。

🔥次のステップは `/api` パスのInress対応、または `/v1` で複数サービスルーティングの **設定のみ** を試しますか？ (アクセス確認は `port-forward` になります)