以下の内容を追記・反映しました：  
- **作業前のクラスター確認と削除方法**  
- **動作確認後のPod削除方法**

リファクタリング後のCKADチュートリアル最新版はこちらです：

---

# 📘 Kubernetesチュートリアル: Pod基礎（nginx版・CKAD本番意識）

このチュートリアルでは、CKAD試験と同様のアプローチを用います：

- `kubectl create`で初期YAML生成
- 最小限の編集でマニフェストを完成させる

---

## 📂 作業ディレクトリ構造

```bash
~/dev/k8s-kind-ckad/01-pod-basic
└── pod-basic.yaml  # kubectlで生成・編集するファイル
```

---

## ✅ 作業前のクラスター状態確認・削除（重要）

**作業開始前に既存のkindクラスタ状態を確認します。不要な場合は削除しましょう。**

- クラスター一覧の確認：

```bash
kind get clusters
```

- 不要なクラスターの削除（例：ckad-cluster）：

```bash
kind delete cluster --name ckad-cluster
```

- クラスター再作成（CKAD試験練習用）：

```bash
kind create cluster --name ckad-cluster
kubectl cluster-info --context kind-ckad-cluster
```

---

## 🚀 Step-by-Step 手順

### ✅ Step 1: YAMLの初期生成（CKAD試験スタイル）

CKAD試験ではマニフェストをゼロから書くのではなく、  
`kubectl create` コマンドを使って初期テンプレートを生成する方法が推奨です。

以下のコマンドでYAMLファイルを生成します。

```bash
cd ~/dev/k8s-kind-ckad/01-pod-basic

kubectl run nginx-pod --image=nginx:latest --dry-run=client -o yaml > pod-basic.yaml
```

**生成された `pod-basic.yaml` の初期内容（例）**

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: nginx-pod
  name: nginx-pod
spec:
  containers:
  - image: nginx:latest
    name: nginx-pod
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

---

### 🛠 Step 2: 必須のYAML修正指示（CKAD本番試験のポイント）

生成されたマニフェストにはいくつか余分な箇所や不足している情報があります。  
CKAD試験の練習として以下の修正をします：

**[修正箇所①]** PodのラベルをCKAD試験で分かりやすく、明示的に変更します：

```diff
metadata:
  labels:
-   run: nginx-pod
+   app: nginx
```

**[修正箇所②]** コンテナ名をシンプルで意味のあるものに変更します：

```diff
containers:
- name: nginx-pod
+ name: nginx-container
```

**[修正箇所③]** ポート番号（80番）を明示的に追加します：

```diff
containers:
  - image: nginx:latest
    name: nginx-container
+   ports:
+     - containerPort: 80
```

---

### ✅ Step 3: 修正後のマニフェスト（完成版）

最終的なYAMLは以下の通りです：

**`pod-basic.yaml`（最終版）**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
    - name: nginx-container
      image: nginx:latest
      ports:
        - containerPort: 80
  restartPolicy: Always
```

- **ポイント**: CKAD本番では、必ずコンテナポートやラベルを明確に指定します。

---

### ✅ Step 4: Podのデプロイ

編集完了後、Podをデプロイします：

```bash
kubectl apply -f pod-basic.yaml
```

---

### ✅ Step 5: Podの確認（CKAD本番の手順に近い方法）

Podの状態をリアルタイムに確認します：

```bash
kubectl get pods -w
```

Podが`Running`になったことを確認したら次へ進みます。

---

### ✅ Step 6: HTTPアクセス確認（ポートフォワード利用）

PodへのHTTPアクセスをテストします（CKAD試験では実際の動作確認も重要）。

```bash
kubectl port-forward pod/nginx-pod 8080:80
```

別ターミナルでHTTPリクエストを送信し、動作を確認します：

```bash
curl -I http://localhost:8080
```

正常なレスポンス：

```http
HTTP/1.1 200 OK
Server: nginx/1.27.0
...
```

---

### 🧹 Step 7: 動作確認後のPod削除方法（重要）

動作確認が完了したら、作成したPodを削除しましょう：

```bash
kubectl delete -f pod-basic.yaml
```

Pod削除の確認：

```bash
kubectl get pods
```

クリーンな状態になっていることを確認してください。

---

## 📌 CKAD試験の観点からポイント整理

CKAD試験では以下が重要になります：

- YAMLをゼロから書くのではなく、`kubectl create/run` コマンドでYAMLを素早く生成
- 必須フィールド（labels, containerPort）を明確に修正
- Podが正常にRunningになること、アクセス可能なことを確認
- 作業スピードと正確性がCKAD合格の鍵

---

## 🚩 推奨使用バージョン（再掲）

|項目|バージョン例|
|---|---|
|OS|Ubuntu 22.04|
|kind|v0.23.0|
|kubectl|v1.29.x|
|Helm|v3.14.x|
|Docker|24.0+|
|AWS CLI|v2|

---

## 🚩 GitHubへのPush（推奨）

完成したマニフェストをGitHubリポジトリにpushします：

```bash
cd ~/dev/k8s-kind-ckad
git add 01-pod-basic
git commit -m "CKAD試験形式でPod基礎（nginx）マニフェスト作成"
git push origin main
```

---

## 🚀 今後の学習ステップ

- **Pod基礎（現在）**
- ConfigMap / Secret連携
- Probe（Liveness / Readiness）の設定
- Service / Ingressを利用したPod公開

---

## 🎖 結論（CKAD試験のためのベストプラクティス）

- CKAD試験では、ゼロからYAMLを書くのではなく、必ず `kubectl create`や`kubectl run`で素早くマニフェストを作成し、必要な箇所のみ修正する方法が推奨です。
- Pod基礎演習は、CKAD合格の重要な出発点です。これをしっかり習得しましょう！🔥