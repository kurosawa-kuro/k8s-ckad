了解です！  
以下は、**ターゲットディレクトリを `~/dev/01-pod-basic-ingress/` に固定した構成**で整理した、Ingress付きnginx公開チュートリアル（EC2 + minikube対応）です👇

---

# 📘 Kubernetesチュートリアル: Pod + Ingressでnginxを外部公開  
📂 `~/dev/k8s-ckad/minikube/01-pod-basic-ingress/`（CKAD × EC2 + minikube）

**目的:** 基本的な Deployment, Service, Ingress を作成し、`kubectl port-forward` でServiceの動作を確認する。

---

## ✅ 0. minikube クラスター管理 (初回またはクリーンアップ時)

```bash
# 既存クラスターの削除（必要な場合）
minikube delete --profile ckad-cluster

# 新規クラスターの作成 (プロファイル名を ckad-cluster に固定)
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

## ✅ 2. nginx Deployment の作成 (deployment.yaml)

```bash
kubectl create deployment nginx-deploy \
  --image=nginx:latest \
  --replicas=1 \
  --port=80 \
  --dry-run=client -o yaml > deployment.yaml
```

生成された `deployment.yaml` を確認（任意）。特に `metadata.labels.app` と `spec.selector.matchLabels.app` が `nginx-deploy` になっていることを確認（Serviceがこれを使うため）。もし `nginx` なら手動で `nginx-deploy` に修正推奨。

適用：

```bash
kubectl apply -f deployment.yaml
```

---

## ✅ 3. ClusterIP Service の作成 (service.yaml)

```bash
# Deployment 'nginx-deploy' を公開
kubectl expose deployment nginx-deploy \
  --name=nginx-service \
  --port=80 \
  --target-port=80 \
  --type=ClusterIP \
  --dry-run=client -o yaml > service.yaml
```

生成された `service.yaml` を確認（任意）。`spec.selector` が Deployment のラベル (`app: nginx-deploy`) と一致していることを確認。

適用：

```bash
kubectl apply -f service.yaml
```

---

## ✅ 4. Ingressリソース作成 (ingress.yaml)

```bash
# Service 'nginx-service' へのルートを作成
kubectl create ingress nginx-ingress \
  --rule="/=nginx-service:80" \
  --dry-run=client -o yaml > ingress.yaml
```

生成された `ingress.yaml` を確認（任意）。`spec.rules[0].http.paths[0].backend.service.name` が `nginx-service` になっていることを確認。

適用：

```bash
kubectl apply -f ingress.yaml
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
# ローカルポート 8080 を Service 'nginx-service' のポート 80 に転送
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

# Kubernetesリソースの削除 (ファイル名で指定)
kubectl delete -f ingress.yaml
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml

# minikube クラスターの削除（不要な場合）
minikube delete --profile ckad-cluster
```

---

## ✅ ファイル構成（完成時）

```bash
~/dev/k8s-ckad/minikube/01-pod-basic-ingress/
├── deployment.yaml
├── service.yaml
└── ingress.yaml
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

1. **Namespace:** このチュートリアルでは `default` Namespaceを使用します。他のチュートリアルで `ckad-ns` など別のNamespaceを使う場合は、コマンドに `-n ckad-ns` を追加してください。
2. **minikubeプロファイル:** 全てのチュートリアルで `ckad-cluster` を使用します。
   ```bash
   minikube start --profile ckad-cluster
   minikube addons enable ingress -p ckad-cluster
   ```
3. **ポートフォワード:** `kubectl port-forward` で使用するローカルポート (`8080`) は、他のプロセスと競合しないように注意してください。
4. **アクセス方法:** このチュートリアルでは `kubectl port-forward` を使用し、`localhost:8080` (EC2インスタンス内) でアクセス確認します。
5. **トラブルシューティング:**
   - `port-forward` がエラーになる場合: Service (`nginx-service`) や Deployment (`nginx-deploy`) が正しく起動しているか確認 (`kubectl get svc,deploy,pods`)。
   - Ingressコントローラーが起動しない場合: `kubectl describe pod -n ingress-nginx`で詳細を確認。

🔥次のステップは、この構成をベースに `/api` パス対応や複数サービスルーティングの設定に進みますか？ (アクセス確認は `port-forward` になります)