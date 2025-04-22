# 📘 Minikube リセット → ECR 認証 → RBAC 検証（CKAD 対応・Namespace **ckad‑ns** 統一）

このチュートリアルは **クラスターを完全にリセット** したうえで

1. **ECR 認証シークレット** を用意し、
2. **RBAC (ServiceAccount / Role / RoleBinding)** を作成し、
3. `bitnami/kubectl` Pod で権限制御を検証

するところまでをワンストップで解説します。

---

## 🔧 0. フルリセット用シェルスクリプト

```bash
#!/usr/bin/env bash
set -euo pipefail

PROFILE="ckad-cluster"
NS="ckad-ns"
REGISTRY="986154984217.dkr.ecr.ap-northeast-1.amazonaws.com"

# 0‑1. 既存リソース削除
kubectl delete deployment,node,svc,pod,role,rolebinding,sa --all -n "$NS" --ignore-not-found
kubectl delete secret ecr-registry-secret -n "$NS" --ignore-not-found
kubectl delete namespace "$NS" --ignore-not-found || true
minikube delete --profile "$PROFILE" || true

# 0‑2. クラスター再作成
minikube start --profile "$PROFILE"

# 0‑3. docker-env 切替え (ECR ログイン用)
eval "$(minikube -p "$PROFILE" docker-env)"

# 0‑4. 名前空間作成
kubectl create namespace "$NS"

# 0‑5. ECR ログイン & Secret 作成
aws ecr get-login-password --region ap-northeast-1 | \
  docker login --username AWS --password-stdin "$REGISTRY"
ECR_PASS=$(aws ecr get-login-password --region ap-northeast-1)
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server="$REGISTRY" \
  --docker-username=AWS \
  --docker-password="$ECR_PASS" \
  -n "$NS"

# 0‑6. Context を ckad-ns に固定
kubectl config set-context --current --namespace="$NS"

echo "✅ リセット + 準備完了 (${PROFILE}/${NS})"
```

> スクリプト保存後 `bash reset.sh` でフルクリーン環境が整います。

---

## 🏗️ RBAC リソースの作成手順

> 以降は **Namespace `ckad‑ns`** にいる前提です（`kubectl config view --minify` で確認可）。

### 1. ServiceAccount

```bash
kubectl create serviceaccount app-sa -n ckad-ns --dry-run=client -o yaml > serviceaccount.yaml
```

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: ckad-ns
  labels:
    app: express-api
```

### 2. Role

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
```

### 3. RoleBinding

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
```

### 4. 検証用 Pod (bitnami/kubectl)

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
  imagePullSecrets:
    - name: ecr-registry-secret
  containers:
    - name: kubectl
      image: bitnami/kubectl
      command: ["sleep", "3600"]
  restartPolicy: Never
```

```bash
kubectl apply -f serviceaccount.yaml -f role.yaml -f rolebinding.yaml -f pod.yaml
```

---

## 🔍 動作確認

```bash
kubectl wait --for=condition=ready pod/rbac-test --timeout=60s

# 許可: get/list
kubectl exec rbac-test -- kubectl get pods -n ckad-ns | head

# 禁止: delete
kubectl exec rbac-test -- kubectl delete pod rbac-test || echo "✅ delete は Forbidden"
```

---

## 📄 完成版 YAML 一覧

> **全ファイル Namespace は `ckad-ns`** — そのまま `kubectl apply -f` で動きます。

| ファイル | 内容 |
|----------|------|
| `serviceaccount.yaml` | ServiceAccount (`app-sa`) |
| `role.yaml` | Role (`pod-reader`) |
| `rolebinding.yaml` | RoleBinding (`read-pods-binding`) |
| `pod.yaml` | 検証用 Pod (`rbac-test`) |

（上記 YAML は本文セクション 1‑4 に掲載済み）

---

### ✅ CKAD でのカギ

* **Namespace を揃える**  ─ Role / RoleBinding / SA / Pod で不一致だと Forbidden になりやすい
* **`kubectl run --dry-run` で雛形生成 → 最小編集** で時短
* **`kubectl exec` で API 実行** して RBAC を即検証

これで「リセット済み Minikube → ECR 認証 → RBAC 検証」までが１コマンド＆一枚のドキュメントで完了します。

