了解です！  
以下は、**ターゲットディレクトリを `~/dev/01-pod-basic-ingress/` に固定した構成**で整理した、Ingress付きnginx公開チュートリアル（EC2 + minikube対応）です👇

---

# 📘 Kubernetesチュートリアル: Pod + Ingressでnginxを外部公開  
📂 `~/dev/01-pod-basic-ingress/`（CKAD × EC2 + minikube）

---

## ✅ 0. ディレクトリ準備

```bash
mkdir -p ~/dev/01-pod-basic-ingress
cd ~/dev/01-pod-basic-ingress
```

---

## ✅ 1. nginx Deployment の作成

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

## ✅ 2. ClusterIP Service の作成

```yaml
# nginx-svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

保存して適用：

```bash
kubectl apply -f nginx-svc.yaml
```

---

## ✅ 3. Ingressリソース作成

```yaml
# nginx-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
spec:
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx-service
                port:
                  number: 80
```

適用：

```bash
kubectl apply -f nginx-ingress.yaml
```

---

## ✅ 4. Ingress Controller の有効化（1度だけでOK）

```bash
# プロファイルを指定してIngressを有効化
minikube addons enable ingress -p ckad-cluster
```

確認：

```bash
kubectl get pods -n ingress-nginx
```

---

## ✅ 5. `minikube tunnel` 実行（別ターミナル or tmux）

```bash
# プロファイルを指定してtunnelを実行
minikube tunnel -p ckad-cluster
```

これにより `Ingress` に外部IPが付与されます。

確認：

```bash
kubectl get ingress nginx-ingress
```

---

## ✅ 6. 外部ブラウザからアクセスする

### 6-1. EC2のセキュリティグループ設定

1. AWSコンソールでEC2インスタンスのセキュリティグループを開く
2. インバウンドルールを編集
3. 以下のルールを追加：
   - タイプ: HTTP (80)
   - ソース: 0.0.0.0/0（すべてのIPからアクセス許可）
   - 説明: Allow HTTP traffic for Ingress

### 6-2. アクセス確認

- EC2の **Elastic IP（またはパブリックIP）** を確認
- `minikube tunnel` により `/` パスでアクセス可能に

確認コマンド：

```bash
# ローカルからのアクセス確認（minikube IP使用）
curl http://192.168.49.2/

# 外部からのアクセス確認（EC2のパブリックIP使用）
curl http://<EC2-IP>/
```

またはブラウザで `http://<EC2-IP>/`  
→ nginx の Welcome画面が表示されれば成功 🎉

---

## ✅ 7. クリーンアップ

```bash
kubectl delete -f nginx-ingress.yaml
kubectl delete -f nginx-svc.yaml
kubectl delete -f nginx-deploy.yaml
```

---

## ✅ ファイル構成（完成時）

```bash
~/dev/01-pod-basic-ingress/
├── nginx-deploy.yaml
├── nginx-svc.yaml
└── nginx-ingress.yaml
```

---

## 🎯 CKAD＋実運用ハイブリッドな学習に最適！

| スキル           | 内容                       |
|------------------|----------------------------|
| 試験対策         | Deployment, Service, Ingress, YAML構成 |
| 実運用準拠       | `minikube tunnel` + EC2パブリックIP外部公開 |
| マニフェスト練習 | `kubectl create --dry-run=client -o yaml` を反復練習 |

---

## 📝 注意事項

1. minikubeプロファイルの確認と指定
   ```bash
   # プロファイル一覧の確認
   minikube profile list
   
   # プロファイルの指定（例：ckad-cluster）
   minikube addons enable ingress -p ckad-cluster
   minikube tunnel -p ckad-cluster
   ```

2. プロファイルの切り替え
   ```bash
   # プロファイルの切り替え
   minikube profile ckad-cluster
   
   # 現在のプロファイルの確認
   minikube profile
   ```

3. アクセス方法の違い
   - ローカル（EC2内）からのアクセス: `http://192.168.49.2/`
   - 外部からのアクセス: `http://<EC2-パブリックIP>/`

4. トラブルシューティング
   - 外部からアクセスできない場合: EC2のセキュリティグループを確認
   - `minikube tunnel`が失敗する場合: プロファイルが正しく指定されているか確認
   - Ingressコントローラーが起動しない場合: `kubectl describe pod -n ingress-nginx`で詳細を確認

必要ならこのチュートリアルをGitHub用Markdownテンプレにも変換します！  
🔥次のステップは `/api` パスのInress対応、または `/v1` で複数サービスルーティングですか？