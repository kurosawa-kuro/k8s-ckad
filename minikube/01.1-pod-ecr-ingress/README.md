# 📘 Kubernetesチュートリアル: Pod基礎（プライベートECRイメージ版・CKAD本番意識）

このチュートリアルでは、パブリックイメージ (Nginx) の代わりに、プライベートなAWS ECRリポジトリにあるNode.js APIイメージ (`container-nodejs-api-8000`) を使用してPodを起動します。コンテナはポート8000でリッスンします。

CKAD試験と同様のアプローチを用います：
- `kubectl create`で初期YAML生成
- 最小限の編集でマニフェストを完成させる

---

## 📋 前提条件

### 1. ECRイメージ情報

| 項目 | 詳細 |
|------|-------|
| メインイメージ | `986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5` |
| ポート | 8000 |
| Gitリポジトリ | [container-nodejs-api-8000](https://github.com/kurosawa-kuro/container-nodejs-api-8000) |

### 2. AWS CLIとDockerの設定

ローカル環境でAWS ECRにアクセスできるように設定が必要です。**この手順はチュートリアル開始前に一度だけ実行すれば、通常は再実行不要です。**

```bash
# AWS CLIの設定 (未設定の場合)
# aws configure

# DockerがECRにログインできるように認証情報を取得・設定
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin 986154984217.dkr.ecr.ap-northeast-1.amazonaws.com
```
*   **重要:** 上記コマンドを実行すると、`$HOME/.docker/config.json` に認証情報が保存されます。これが後のSecret作成ステップで必要になります。

---

## 🛠️ Minikube/kubectlのインストール（未実施の場合）

```bash
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

---

## 📂 作業ディレクトリ構造

```bash
~/dev/k8s-ckad/minikube/01.1-pod-ecr
└── pod-ecr.yaml  # kubectlで生成・編集するファイル
```

---

## 🚀 Step-by-Step 手順

### ✅ Step 0: Minikubeクラスターの準備

**作業開始前に既存のminikubeプロファイル状態を確認し、必要であればクリーンな状態から開始します。**

1.  **クラスター（プロファイル）一覧の確認：**
    ```bash
    minikube profile list
    ```
2.  **不要なクラスター（プロファイル）の削除（例：ckad-cluster）：**
    ```bash
    # 既存のクラスターがあれば削除
    minikube delete --profile ckad-cluster
    ```
3.  **クラスター（プロファイル）作成（CKAD試験練習用）：**
    ```bash
    minikube start --profile ckad-cluster
    ```
4.  **kubectlコンテキストとクラスター情報の確認:**
    ```bash
    # 現在のkubectlコンテキストが ckad-cluster になっていることを確認
    kubectl config current-context
    kubectl cluster-info
    ```

### ✅ Step 1: Kubernetes Secretの作成 (ECR認証用)

**Minikubeクラスターが起動している状態で、** KubernetesがECRからプライベートイメージをプルできるようにSecretを作成します。

```bash
kubectl create secret generic ecr-registry-secret \
  --from-file=.dockerconfigjson=$HOME/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson
```
*   **重要:** このステップは、**Minikubeクラスターを起動または再作成するたびに実行する必要があります。**
*   **確認:** `kubectl get secret ecr-registry-secret -o yaml` でSecretが作成されたか確認できます。

### ✅ Step 2: YAMLの初期生成（CKAD試験スタイル）

`kubectl run` コマンドでPodの基本的なYAMLテンプレートを生成します。

```bash
# 作業ディレクトリへ移動 (まだ移動していない場合)
cd ~/dev/k8s-ckad/minikube/01.1-pod-ecr

# ECRイメージを指定してYAMLを生成
kubectl run nodejs-api-pod \
  --image=986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5 \
  --dry-run=client -o yaml > pod-ecr.yaml
```

**生成された `pod-ecr.yaml` の初期内容（例）**
```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: nodejs-api-pod # 後で修正
  name: nodejs-api-pod
spec:
  containers:
  - image: 986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5
    name: nodejs-api-pod # 後で修正
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always # 用途に応じて Never や OnFailure に変更も検討
status: {}
```

---

### 🛠 Step 3: 必須のYAML修正指示（CKAD本番試験のポイント）

生成されたマニフェスト (`pod-ecr.yaml`) を編集し、必要な情報を追加・修正します。

**[修正箇所①]** Podのラベルを分かりやすく変更します：
```diff
metadata:
  labels:
-   run: nodejs-api-pod
+   app: nodejs-api
```
**[修正箇所②]** コンテナ名を具体的に変更します：
```diff
containers:
- name: nodejs-api-pod
+ name: nodejs-api-container
```
**[修正箇所③]** コンテナがリッスンするポート (8000番) を明示的に追加します：
```diff
containers:
  - image: 986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5
    name: nodejs-api-container
+   ports:
+   - containerPort: 8000
```
**[修正箇所④]** ECRからイメージをプルするためのSecret (`imagePullSecrets`) を追加します：
```diff
spec:
+ imagePullSecrets:
+ - name: ecr-registry-secret
  containers:
  - image: 986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5
    name: nodejs-api-container
```
*   **注意:** `imagePullSecrets` は `spec` 直下、`containers` と同じレベルに追加します。

---

### ✅ Step 4: 修正後のマニフェスト（完成版）

最終的な `pod-ecr.yaml` は以下のようになります。

**`pod-ecr.yaml`（最終版）**
```yaml
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
      resources: {} # 必要に応じてリソースリクエスト/リミットを設定
  dnsPolicy: ClusterFirst
  restartPolicy: Always
```

- **ポイント**: プライベートリポジトリの場合は `imagePullSecrets` の指定が不可欠です。

---

### ✅ Step 5: Podのデプロイ

編集完了後、Podをデプロイします：
```bash
kubectl apply -f pod-ecr.yaml
```

---

### ✅ Step 6: Podの確認（CKAD本番の手順に近い方法）

Podの状態を確認します。`ImagePullBackOff` などのエラーが出ていないか注意深く見ます。
```bash
kubectl get pods -w
# または詳細を確認
# kubectl describe pod nodejs-api-pod
```
Podが `Running` になれば成功です。イメージのプルに時間がかかる場合があります。

---

### ✅ Step 7: HTTPアクセス確認（ポートフォワード利用）

Pod内のコンテナ (ポート8000) へローカルからアクセスできるようにポートフォワードを設定します。
```bash
# ローカルポート 8000 をPodのポート 8000 にフォワード
kubectl port-forward pod/nodejs-api-pod 8000:8000
```
*   これにより、ローカルマシンのポート `8000` へのアクセスがPodのポート `8000` に転送されます。

別ターミナルを開き、`curl` でアクセスして動作を確認します：
```bash
# フォワード先のローカルポート 8000 にアクセス
curl http://localhost:8000/
```

Node.js APIのルート (`/`) が返すレスポンス（例: `{"message":"Hello World!"}` など）が表示されれば成功です。

---

### 🧹 Step 8: 動作確認後のPod削除方法（重要）

動作確認が完了したら、作成したPodを削除します：
```bash
kubectl delete -f pod-ecr.yaml
```

Pod削除の確認：
```bash
kubectl get pods
```
クリーンな状態になっていることを確認してください。

*   **補足:** 作成した `ecr-registry-secret` は、クラスターを削除すると失われます。クラスターを起動し直した場合は Step 1 から再度実行してください。

---

## 📌 CKAD試験の観点からポイント整理

- `kubectl run` で基本YAMLを生成し、迅速に編集する。
- プライベートリポジトリ利用時は `imagePullSecrets` を忘れずに追加する。
- Pod名、コンテナ名、ラベル、ポート番号を仕様に合わせて正確に設定する。
- `kubectl describe pod <pod-name>` でエラー原因を特定する能力も重要。

---

## 🚩 推奨使用バージョン（再掲）

|項目|バージョン例|
|---|---|
|OS|Ubuntu 22.04|
|minikube|v1.33.x|
|kubectl|v1.29.x|
|Docker|24.0+|
|AWS CLI|v2|

---

## 🚩 GitHubへのPush（推奨）

完成したマニフェストをGitHubリポジトリにpushします：
```bash
cd ~/dev/k8s-ckad/minikube # プロジェクトルートに移動
git add 01.1-pod-ecr
git commit -m "feat(ckad/minikube): 01.1-pod-ecr ECRイメージ利用チュートリアル追加"
git push origin main
```

---

## 🚀 今後の学習ステップ

- **Pod基礎 (ECR版)（現在）**
- ConfigMap / Secret連携 (環境変数など)
- Deploymentを利用したPod管理
- ServiceによるPodへの安定したアクセス提供

---

## 🎖 結論（CKAD試験のためのベストプラクティス）

- プライベートイメージの扱いはCKAD試験でも出題される可能性があります。`imagePullSecrets` の作成とPodマニフェストへの適用方法を確実に習得しましょう。
- 単純なNginxだけでなく、実際のアプリケーションに近いイメージ（例: Node.js API）での演習は理解を深めます。🔥