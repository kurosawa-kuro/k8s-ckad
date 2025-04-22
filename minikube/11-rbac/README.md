# 📘 Kubernetesチュートリアル: RBAC + ServiceAccount（bitnami/kubectl・Minikube 版 / CKAD 対応）

>  **前提** : コントロールプレーンは *Minikube*（docker ドライバ想定）、ネームスペースは `default` を使用します。
>  ローカル検証で kind ではなく Minikube を使う場合のコマンド差分を明示しています。

---

## 📂 作業ディレクトリ構成（例）

```bash
~/dev/k8s-ckad/minikube/02-rbac/
├── serviceaccount.yaml
├── role.yaml
├── rolebinding.yaml
└── pod.yaml
```

---

## ✅ Step 1 — Minikube クラスター起動（既存のクラスターがあればスキップ）

```bash
minikube start --profile ckad-rbac
kubectl config use-context ckad-rbac   # プロファイル名と同じ context が作成される
```

> kind と違い、`kubectl cluster-info` の URL は `https://192.168.*:8443` になりますがチュートリアルには影響しません。

---

## ✅ Step 2 — ServiceAccount を作成

```bash
kubectl create serviceaccount app-sa \
  --dry-run=client -o yaml > serviceaccount.yaml
```

手直し（オプションでラベル付与）:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  labels:
    app: express-api
```

```bash
kubectl apply -f serviceaccount.yaml
```

---

## ✅ Step 3 — Role を作成（Pod の get/list 権限）

```yaml
# role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  labels:
    app: express-api
rules:
  - apiGroups: [""]        # "" = Core API グループ
    resources: ["pods"]
    verbs: ["get", "list"]
```

```bash
kubectl apply -f role.yaml
```

---

## ✅ Step 4 — RoleBinding を作成

```yaml
# rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods-binding
  labels:
    app: express-api
subjects:
  - kind: ServiceAccount
    name: app-sa
    namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

```bash
kubectl apply -f rolebinding.yaml
```

---

## ✅ Step 5 — 検証用 Pod (bitnami/kubectl) を生成

```bash
kubectl run rbac-test \
  --image=bitnami/kubectl \
  --serviceaccount=app-sa \
  --restart=Never --dry-run=client -o yaml \
  -- sleep 3600 > pod.yaml
```

最小編集ポイント:
* `metadata.labels` を足す場合は `app: express-api`

```bash
kubectl apply -f pod.yaml
```

Minikube では **containerd** ランタイムが既定なので、イメージプルに時間がかかる場合は `minikube image load bitnami/kubectl` で先にローカル読み込みしておくと高速化できます。

---

## 🔍 Step 6 — RBAC 動作確認

```bash
# Pod が Ready になるまで待機
kubectl wait --for=condition=ready pod/rbac-test --timeout=60s

# 許可された操作 (get/list)
kubectl exec rbac-test -- kubectl get pods -n default | head

# 禁止された操作 (delete) → "forbidden" エラーになるはず
kubectl exec rbac-test -- kubectl delete pod rbac-test || echo "✅ delete は禁止されている"
```

---

## 📝 CKAD でのハイライト

| ポイント | コマンド例 | 解説 |
|----------|-----------|------|
| YAML ひな形生成 | `kubectl create serviceaccount` / `kubectl run --dry-run` | 手入力を最小化 |
| Role / RoleBinding | Core vs 他 API グループ識別 | `apiGroups: [""]` で core |
| 検証方法 | `kubectl exec -- kubectl get pods` | SA の権限で実際の API 呼び出し |
| Minikube 特有 | `minikube image load` | containerd でプルを高速化 |

これで **Minikube ベースの RBAC 検証チュートリアル** が完成です。CKAD 試験でも同じ手順で応用できます！


---

## 📄 完成版 YAML 集

> 下記 4 ファイルを保存し、そのまま `kubectl apply -f <file>` すれば一連の RBAC 検証が完了します。

### 1. `serviceaccount.yaml`
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: ckad-ns
  labels:
    app: express-api
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  labels:
    app: express-api
```

### 2. `role.yaml`
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: ckad-ns
  labels:
    app: express-api
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  labels:
    app: express-api
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
```

### 3. `rolebinding.yaml`
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods-binding
  namespace: ckad-ns
  labels:
    app: express-api
subjects:
  - kind: ServiceAccount
    name: app-sa
    namespace: ckad-ns
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods-binding
  labels:
    app: express-api
subjects:
  - kind: ServiceAccount
    name: app-sa
    namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### 4. `pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: rbac-test
  namespace: ckad-ns
  labels:
    app: express-api
spec:
  serviceAccountName: app-sa
  containers:
    - name: nodejs-api-kubectl
      image: bitnami/kubectl
      command: ["sleep", "3600"]
  restartPolicy: Never
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: rbac-test
  labels:
    app: express-api
spec:
  serviceAccountName: app-sa
  containers:
    - name: nodejs-api-kubectl
      image: bitnami/kubectl
      command: ["sleep", "3600"]
  restartPolicy: Never
```

---

