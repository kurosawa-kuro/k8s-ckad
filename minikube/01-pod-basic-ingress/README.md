了解です！  
以下は、**ターゲットディレクトリを `~/dev/01-pod-basic-ingress/` に固定した構成**で整理した、Ingress付きnginx公開チュートリアル（EC2 + minikube対応）です👇

---

# 📘 Kubernetesチュートリアル: Pod + Ingressでnginxを外部公開（Namespace対応）

📂 `~/dev/k8s-ckad/minikube/01-pod-basic-ingress/`  
**目的:** Namespaceを明示して、Deployment, Service, Ingress を作成し、`kubectl port-forward` で確認。

---

## ✅ 0. クラスター起動（初回 or リセット時）

```bash
# 既存クラスターの削除（必要な場合）
minikube delete --profile ckad-cluster

# minikube クラスター作成（プロファイル固定: ckad-cluster）
minikube start --profile ckad-cluster

# 状態確認
minikube status -p ckad-cluster
kubectl cluster-info
```

--- 

## ✅ 1. 事前準備：Namespaceの作成と設定

```bash
# 今回使用する Namespace を作成
kubectl create namespace ckad-pod-ingress

# 現在の context に Namespace を設定（※重要）
# これ以降の kubectl コマンドはこの Namespace で実行される
kubectl config set-context --current --namespace=ckad-pod-ingress
```

--- 

## ✅ 2. ディレクトリ準備

```bash
mkdir -p ~/dev/k8s-ckad/minikube/01-pod-basic-ingress
cd ~/dev/k8s-ckad/minikube/01-pod-basic-ingress
```

--- 

## ✅ 3. Deployment作成（deployment.yaml）

```bash
# nginx-deploy という名前で Deployment を作成
kubectl create deployment nginx-deploy \
  --image=nginx:latest \
  --replicas=1 \
  --port=80 \
  --dry-run=client -o yaml > deployment.yaml
```

適用：

```bash
# 現在設定されている Namespace (ckad-pod-ingress) に適用される
kubectl apply -f deployment.yaml
```

--- 

## ✅ 4. Service作成（service.yaml）

```bash
# nginx-deploy Deployment を公開する Service を作成
kubectl expose deployment nginx-deploy \
  --name=nginx-service \
  --port=80 \
  --target-port=80 \
  --type=ClusterIP \
  --dry-run=client -o yaml > service.yaml
```

適用：

```bash
# 現在設定されている Namespace (ckad-pod-ingress) に適用される
kubectl apply -f service.yaml
```

--- 

## ✅ 5. Ingress作成（ingress.yaml）

```bash
# nginx-service へのルートを持つ Ingress を作成
kubectl create ingress nginx-ingress \
  --rule="/=nginx-service:80" \
  --dry-run=client -o yaml > ingress.yaml
```

適用：

```bash
# 現在設定されている Namespace (ckad-pod-ingress) に適用される
kubectl apply -f ingress.yaml
```

--- 

## ✅ 6. port-forward でアクセス確認

```bash
# nginx-service (ckad-pod-ingress Namespace 内) へのポートフォワード
# (フォアグラウンドで実行、Ctrl+Cで停止)
kubectl port-forward svc/nginx-service 8080:80
```

別ターミナルで実行：

```bash
# ローカルホスト (EC2インスタンス内) からアクセス
curl localhost:8080
```

→ nginx の Welcome画面が表示されれば成功 🎉

--- 

## ✅ 7. クリーンアップ

```bash
# port-forward を Ctrl+C で停止

# ckad-pod-ingress Namespace 内のリソースを削除
kubectl delete -f ingress.yaml
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml

# Namespace削除（希望する場合）
kubectl delete ns ckad-pod-ingress

# デフォルトNamespaceに戻す（任意）
# kubectl config set-context --current --namespace=default
```

--- 

## ✅ ファイル構成

```bash
~/dev/k8s-ckad/minikube/01-pod-basic-ingress/
├── deployment.yaml
├── service.yaml
└── ingress.yaml
```

--- 

## 🎯 CKAD学習ポイント

| 項目 | 内容 |
|------|------|
| 試験形式準拠 | Namespace作成＆コンテキスト設定 (`set-context`) 対応済み  
| リソース構成力 | Deployment / Service / Ingressの基礎固め  
| 動作確認力 | `port-forward`によるServiceへの直接アクセス確認（試験通り）  
| Namespace意識 | リソースがどのNamespaceに作成されるかを意識する練習  
| ミス対策 | クリーンアップ手順とNamespaceの分離による影響範囲限定  

--- 

これで「Namespaceあり前提」の試験形式に完全一致するチュートリアルになりました💯  
次に `/api` ルートや `readinessProbe` に進んでも、この形で横展開できます！

準備できたら「次これ行く」で呼んでね🔥