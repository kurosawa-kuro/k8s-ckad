以下の通り、**ConfigMap** と **Secret** を使用した設定管理に関する **CKAD試験対策チュートリアル** の手順を整理し、コマンドを示します。

---

# 📘 CKAD試験対策チュートリアル: **ConfigMapおよびSecretを使用した設定外部化**

## ✅ チュートリアルの目的

- Kubernetesの **ConfigMap** と **Secret** リソースを活用し、アプリケーションの設定や機密情報を外部化・安全に管理する方法を学習します。
- CKAD試験で必要な設定外部化および機密情報の取り扱い方法を身につけることを目的とします。

## ✅ 作業ディレクトリ提案

作業ディレクトリは以下を固定します：

```bash
~/dev/k8s-kind-ckad
```

今回のチュートリアル用ディレクトリ名は `05-configmap-secret` です。

---

## ✅ コンテナイメージの選定

**Option A**: パブリック軽量イメージ (`nginx` または `busybox`)

- **利点**: 軽量で、ConfigMapおよびSecretの動作確認に最適。

**Option B**: **Node.js Express API (AWS ECRプライベートイメージ)**

- **利点**: 実際のアプリケーション設定を学ぶには適していますが、設定反映確認には少し過剰。

### 提案

- **Option A**（`busybox`）が良いでしょう。軽量でシンプルな環境で設定をテストするため、最適です。

---

## ✅ YAML作成手順（CKAD試験スタイルを意識）

### **1. `kubectl create` コマンドで初期YAMLを迅速に生成**

`kubectl create` を使って初期YAMLファイルを生成します。

```bash
kubectl run myapp-pod \
  --image=busybox:latest \
  --dry-run=client -o yaml > myapp-pod.yaml
```

このコマンドで生成される **`myapp-pod.yaml`** の例（初期状態）:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  containers:
  - name: myapp-container
    image: busybox:latest
    command: ["sleep", "3600"]
```

### **2. YAMLファイルの修正**

#### **[修正箇所①]** ラベルの追加:

```diff
metadata:
  name: myapp-pod
- labels:
-   run: myapp-pod
+ labels:
+   app: myapp-app
```

#### **[修正箇所②]** ConfigMapとSecretの注入

まずはConfigMapとSecretを作成します。

**ConfigMapの作成**:

```bash
kubectl create configmap myapp-config --from-literal=APP_ENV=production --dry-run=client -o yaml > configmap.yaml
```

**Secretの作成**:

```bash
kubectl create secret generic myapp-secret --from-literal=DB_PASSWORD=mysecretpassword --dry-run=client -o yaml > secret.yaml
```

次に、Podにこれらの設定を適用します。

**`myapp-pod.yaml`の修正**:

```diff
spec:
  containers:
  - name: myapp-container
    image: busybox:latest
    command: ["sleep", "3600"]
+    envFrom:
+    - configMapRef:
+        name: myapp-config
+    - secretRef:
+        name: myapp-secret
```

この修正により、Podは **ConfigMap** と **Secret** の設定を環境変数として受け取ります。

### 完成した **`myapp-pod.yaml`**:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app: myapp-app
spec:
  containers:
  - name: myapp-container
    image: busybox:latest
    command: ["sleep", "3600"]
    envFrom:
    - configMapRef:
        name: myapp-config
    - secretRef:
        name: myapp-secret
```

---

## ✅ 動作確認手順

1. **ConfigMapとSecretの作成**

```bash
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
```

2. **Podのデプロイ**

```bash
kubectl apply -f myapp-pod.yaml
```

3. **Podの状態確認**

```bash
kubectl get pods
```

4. **Pod内でConfigMapとSecretが正しく設定されていることを確認**

Pod内で設定を確認します。

```bash
kubectl exec myapp-pod -- printenv APP_ENV
kubectl exec myapp-pod -- printenv DB_PASSWORD
```

これにより、`APP_ENV` と `DB_PASSWORD` の値が **ConfigMap** と **Secret** から正しく取得されていることを確認できます。

---

## ✅ 重要ポイント整理

- YAML生成は `kubectl create` を使って迅速に行う。
- 必須フィールド（`labels`, `containerPort`, `envFrom`）を明確に設定する。
- ConfigMapとSecretの設定を環境変数としてPodに注入する方法を理解する。
- 作業スピードと正確性がCKAD試験合格の鍵。

---

## ✅ 推奨環境

| 項目        | バージョン例        |
|-------------|--------------------|
| OS          | Ubuntu 22.04        |
| kind        | v0.23.0            |
| kubectl     | v1.29.x            |
| Helm        | v3.14.x            |
| Docker      | 24.0+              |
| AWS CLI     | v2 (ECR認証のため必須) |

---

## ✅ GitHubへのPush手順（推奨）

```bash
cd ~/dev/k8s-kind-ckad
git add 05-configmap-secret
git commit -m "CKAD試験対策: ConfigMap・Secretを使用した設定外部化"
git push origin main
```

---

## ✅ チュートリアル完了時のゴール

- **CKAD試験** で **ConfigMap** と **Secret** を使用した設定外部化・機密情報管理を迅速かつ正確に行えるようになる。
- Kubernetes環境で **ConfigMap** と **Secret** を安全に管理し、実務でも活用できる。

---

**これでCKAD試験対策として、ConfigMapとSecretを使用した設定外部化が完了しました！**