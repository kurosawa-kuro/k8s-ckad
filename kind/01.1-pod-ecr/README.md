理解しました。今回の指示に従い、**nginx**を**Express API**に変更し、Podの基本的な設定を行います。

以下の手順を踏んでリファクタリングしたYAMLを作成します。

---

# 📘 **Kubernetesチュートリアル: Pod基礎（Express API版）**

このチュートリアルでは、Express APIを使用したPodを作成し、基本的な設定を行います。`kubectl create`でYAMLを生成し、必要な修正を加えた後、Podをデプロイします。

---

## 📂 **作業ディレクトリ構造**

```bash
~/dev/k8s-kind-ckad/01.1-pod-ecr
└── pod-express.yaml  # kubectlで生成・編集するファイル
```

---

## 🚀 **手順詳細**

### ✅ **Step 1: YAMLの初期生成（Express版）**

まず、Expressを使用したAPIを実行するPodの初期YAMLを生成します。今回は`kubectl run`で簡単に生成します。

```bash
cd ~/dev/k8s-kind-ckad/01.1-pod-ecr

kubectl run app-pod \
  --image=986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5 \
  --dry-run=client -o yaml > pod-express.yaml
```

### ✅ **Step 2: 必須のYAML修正（Express API版）**

生成されたYAMLにはいくつか不足している部分があるので、CKAD試験に合わせて修正を行います。

```diff
metadata:
  labels:
-   run: app-pod
+   app: nodejs-api

spec:
  containers:
  - image: 986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5
    name: app-container
    ports:
    - containerPort: 8000
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8000
      initialDelaySeconds: 5
      periodSeconds: 5
      failureThreshold: 3
    readinessProbe:
      httpGet:
        path: /delay
        port: 8000
      initialDelaySeconds: 5
      periodSeconds: 5
      failureThreshold: 3
  restartPolicy: Always
```

### ✅ **Step 3: 修正後のマニフェスト（完成版）**

最終的なYAMLは以下の通りです：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
  labels:
    app: nodejs-api
spec:
  imagePullSecrets:
    - name: ecr-registry-secret  # ECR認証のための秘密情報
  containers:
  - name: app-container
    image: 986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5
    ports:
    - containerPort: 8000
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8000
      initialDelaySeconds: 5
      periodSeconds: 5
      failureThreshold: 3
    readinessProbe:
      httpGet:
        path: /delay
        port: 8000
      initialDelaySeconds: 5
      periodSeconds: 5
      failureThreshold: 3
  restartPolicy: Always
```

---

### ✅ **Step 4: Podのデプロイ**

編集完了後、Podをデプロイします：

```bash
kubectl apply -f pod-express.yaml
```

---

### ✅ **Step 5: Podの確認（状態確認）**

Podの状態をリアルタイムで確認します：

```bash
kubectl get pods -w
```

Podが`Running`になったことを確認したら次へ進みます。

---

### ✅ **Step 6: HTTPアクセス確認（ポートフォワード）**

PodへのHTTPアクセスをテストします。`port-forward`を利用して、ローカルマシンからPodのAPIにアクセスします：

```bash
kubectl port-forward pod/app-pod 8080:8000
```

別ターミナルで以下のコマンドを実行し、レスポンスを確認します：

```bash
curl http://localhost:8080/healthz
```

正常なレスポンスが返ってくることを確認します。

---

### 🧹 **Step 7: 動作確認後のPod削除**

動作確認が完了したら、作成したPodを削除します：

```bash
kubectl delete -f pod-express.yaml
```

Pod削除の確認：

```bash
kubectl get pods
```

クリーンな状態になっていることを確認してください。

---

## 📌 **CKAD試験の観点からポイント整理**

- YAMLをゼロから書かず、`kubectl create`コマンドで迅速に生成し、必要な部分だけを修正する方法が推奨です。
- 必須フィールド（`labels`, `containerPort`, `livenessProbe`, `readinessProbe`）を明確に修正します。
- Podが正常に`Running`になること、アクセス可能なことを確認します。
- 作業スピードと正確性がCKAD合格の鍵となります。

---

## 🚩 **推奨使用バージョン**

|項目|バージョン例|
|---|---|
|OS|Ubuntu 22.04|
|kind|v0.23.0|
|kubectl|v1.29.x|
|Helm|v3.14.x|
|Docker|24.0+|
|AWS CLI|v2|

---

## 🚩 **GitHubへのPush手順（推奨）**

完成したYAMLマニフェストをGitHubリポジトリにpushします：

```bash
cd ~/dev/k8s-kind-ckad
git add 01.1-pod-ecr
git commit -m "CKAD試験形式でPod基礎（Express）マニフェスト作成"
git push origin main
```

---

## 🚀 **今後の学習ステップ**

- **Pod基礎（現在）**
- ConfigMap / Secret連携
- Probe（Liveness / Readiness）の設定
- Service / Ingressを利用したPod公開

---

## 🎖 **結論（CKAD試験のためのベストプラクティス）**

- CKAD試験では、ゼロからYAMLを書くのではなく、必ず`kubectl create`や`kubectl run`で迅速にマニフェストを作成し、必要な箇所のみ修正する方法が推奨されます。
- Pod基礎演習は、CKAD合格の重要な出発点です。これをしっかり習得しましょう！

---

以上が、**Expressを使用したPodの基本構成**です。今後のステップに進む際に、`kubectl create`を使用して基本のPodを作成し、必要な修正を加えていきます。