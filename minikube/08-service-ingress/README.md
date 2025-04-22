以下に、CKAD試験対策での**ServiceとIngressによるPodの公開**を実現するためのMinikubeベースのチュートリアルを示します。

### 0. **Minikubeのインストールと準備**

#### 0.1 **Minikubeのインストール（Ubuntu）**

```bash
# 依存パッケージのインストール
sudo apt-get update
sudo apt-get install -y curl wget apt-transport-https

# Docker のインストール（未インストールの場合）
sudo apt-get install -y docker.io
sudo usermod -aG docker $USER
sudo systemctl start docker
sudo systemctl enable docker

# Minikubeのダウンロードとインストール
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# kubectlのインストール
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# バージョン確認
minikube version
kubectl version --client
```

インストール後、一度ログアウトして再ログインするか、以下のコマンドで Docker グループの変更を反映させます：

```bash
newgrp docker
```

#### 0.2 **Minikubeクラスターの起動**

```bash
# Minikubeクラスターの起動
minikube start

# Ingressアドオンの有効化
minikube addons enable ingress

# クラスターの状態確認
minikube status
kubectl cluster-info
```

### 1. **初期YAML生成コマンド**

```bash
kubectl create deployment nginx-app --image=nginx:1.25 --dry-run=client -o yaml > deployment.yaml
```

このコマンドで、サンプルアプリケーションとして`nginx`のコンテナをデプロイするための`deployment.yaml`が生成されます。

### 2. **修正されたDeploymentのYAML（差分形式）**

最初に生成されたYAMLファイルをもとに、以下の内容を修正します。

```diff
spec:
  replicas: 2
  selector:
    matchLabels:
+      app: nginx-app
  template:
    metadata:
      labels:
+        app: nginx-app
    spec:
      containers:
        - name: nginx
          image: nginx:1.25
+          ports:
+            - containerPort: 80
```

修正内容:
- Podの`labels`と`containerPort`を明示的に追加
- `replicas: 2`を設定して2つのPodを複製

### 3. **DeploymentのYAMLマニフェスト（最終版）**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-app
  template:
    metadata:
      labels:
        app: nginx-app
    spec:
      containers:
        - name: nginx
          image: nginx:1.25
          ports:
            - containerPort: 80
```

### 4. **Serviceの作成**

次に、PodにアクセスするためのServiceを作成します。`service.yaml`というファイル名で以下を作成します。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

- **Selector**: `app: nginx-app`というラベルを持つPodにリクエストを転送します。
- **Port**: 外部からのリクエストが`80`ポートでPodに転送されます。

### 5. **Ingressの作成**

次に、外部からのHTTPリクエストをServiceに転送するためのIngressを作成します。以下を`ingress.yaml`として保存します。

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
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

### 6. **動作確認**

次に、以下のコマンドでリソースを適用します。

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```

#### 6.1 **各リソースの状態確認**

```bash
# Podの確認
kubectl get pods -l app=nginx-app -w

# Serviceの確認
kubectl get svc nginx-service

# Ingressの確認
kubectl get ingress nginx-ingress
```

#### 6.2 **Minikubeでのアクセス確認**

Minikubeの環境でIngressのIPアドレスを取得します。

```bash
# 内部IPアドレスの確認 (Lightsailインスタンス内からのアクセス用)
minikube ip
```

取得したIPアドレスを使って、Lightsailインスタンス**内部**から以下のようにアクセスできます：

```bash
# 例：Lightsailインスタンス内からcurlで確認
curl http://$(minikube ip)
```

#### 6.3 **外部からのアクセス確認 (ブラウザなど)**

外部（ローカルPCのブラウザなど）からアクセスするには、`minikube tunnel` を使用します。

1.  **新しいターミナル**を開き、Lightsailインスタンスに接続して以下のコマンドを実行します。パスワードの入力を求められる場合があります。
    ```bash
    minikube tunnel
    ```
    **注意:** このコマンドは実行したままにしておく必要があります。終了すると外部からアクセスできなくなります。

2.  `minikube tunnel` を実行した状態で、ブラウザを開き、**LightsailインスタンスのパブリックIPアドレス** をアドレスバーに入力します。
    ```
    http://<LightsailインスタンスのパブリックIPアドレス>
    ```

    これで、Nginxのデフォルトページが表示されるはずです。

3.  アクセスが終わったら、`minikube tunnel` を実行しているターミナルで `Ctrl+C` を押してトンネルを停止します。

### 7. **トラブルシューティング**

1. **Ingressコントローラーの確認**
```bash
# Ingressコントローラーのポッドの状態確認
kubectl get pods -n ingress-nginx
kubectl describe pods -n ingress-nginx -l app.kubernetes.io/component=controller

# Ingressリソースの状態確認
kubectl get ingress nginx-ingress
kubectl describe ingress nginx-ingress
```

2. **トンネルとルーティングの確認**
```bash
# トンネルの状態確認
minikube tunnel --cleanup
minikube tunnel

# 期待される出力:
# Status:
#         machine: minikube
#         pid: <プロセスID>
#         route: 10.96.0.0/12 -> 192.168.49.2
#         minikube: Running
#         services: []
#     errors: 
#                 minikube: no errors
#                 router: no errors
#                 loadbalancer emulator: no errors
```

3. **Serviceの動作確認**
```bash
# Serviceの詳細確認
kubectl describe svc nginx-service

# エンドポイントの確認
kubectl get endpoints nginx-service

# ポートフォワードを使用した直接確認
kubectl port-forward svc/nginx-service 8080:80
```

別ターミナルで：
```bash
curl http://localhost:8080
```

4. **ネットワーク接続性の確認**
```bash
# Lightsailインスタンス内からの確認
curl -v http://$(minikube ip)

# Ingressの詳細なデバッグ情報
kubectl get events -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

5. **一般的な解決策**
   - Lightsailのファイアウォールでポート80が開いていることを確認
   - `minikube tunnel`を実行中のターミナルを開いたままにする
   - ブラウザからアクセスする場合は、LightsailインスタンスのパブリックIPアドレスを使用
   - 必要に応じて、Ingressコントローラーを再起動:
     ```bash
     kubectl rollout restart deployment ingress-nginx-controller -n ingress-nginx
     ```

### 8. **まとめ**

以下の内容を確認しました：
- **Minikubeの設定**: Ingressアドオンの有効化
- **Deploymentの作成**: Nginxサンプルアプリケーションのデプロイ
- **Serviceの作成**: Podにアクセス可能にする
- **Ingressの作成**: 外部からアプリケーションにアクセス可能にする

CKAD試験において、ServiceおよびIngressを使ったPod公開は重要なスキルです。このチュートリアルを通じて、必要な設定や手順を理解し、試験で素早く設定できるようになります。

注意：CKAD試験では、Minikubeではなく別の環境が使用される可能性がありますが、基本的な概念と設定方法は同じです。試験環境に応じて、適切なコマンドやツールを使用してください。