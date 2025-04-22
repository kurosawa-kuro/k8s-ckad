以下は、**`bitnami/kubectl`** イメージを使用した **RBAC (Role-Based Access Control)** の設定に関する **正解のYAML** です。

---

### 初期YAML生成コマンド

まず、`kubectl run`コマンドを使ってPodの初期YAMLを生成します。

```bash
kubectl run rbac-test --image=bitnami/kubectl --dry-run=client -o yaml -- sleep 3600 > pod.yaml
```

---

### 1. ServiceAccountの作成

まず、ServiceAccountを作成します。

```bash
kubectl create serviceaccount app-sa -o yaml --dry-run=client > serviceaccount.yaml
```

**修正後のYAML** (必要に応じてラベルを追加)：

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  labels:
    app: express-api
```

---

### 2. Roleの作成

次に、特定のNamespace内でPodの`get`、`list`権限を持つRoleを作成します。

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

---

### 3. RoleBindingの作成

RoleBindingを作成し、上記で作成したRoleをServiceAccountにバインドします。

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

---

### 4. Podの作成

次に、`bitnami/kubectl` イメージを使用して、ServiceAccountを指定したPodの作成マニフェストを作成します。

**Pod作成コマンド**:

```bash
kubectl run rbac-test --image=bitnami/kubectl --dry-run=client -o yaml -- sleep 3600 > pod.yaml
```

**修正後のYAML** (必要に応じて`labels`と`serviceAccountName`を追加)：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: rbac-test
  labels:
    app: express-api
spec:
  serviceAccountName: app-sa  # ServiceAccount名を指定
  containers:
    - name: rbac-test
      image: bitnami/kubectl
      command: ["sleep", "3600"]
```

---

### 5. 動作確認

以下の手順で作成したYAMLを適用し、動作を確認します。

1. **ServiceAccount、Role、RoleBinding、Podの適用**:

```bash
kubectl apply -f serviceaccount.yaml
kubectl apply -f role.yaml
kubectl apply -f rolebinding.yaml
kubectl apply -f pod.yaml
```

2. **Podの状態確認**:

```bash
kubectl get pods
```

3. **Pod内で権限テスト**:

```bash
kubectl exec -it rbac-test -- kubectl get pods  # 成功するはずです（許可された操作）
kubectl exec -it rbac-test -- kubectl delete pod rbac-test  # 失敗するはずです（許可されていない操作）
```

---

### CKAD試験での重要ポイント

- `kubectl create`コマンドを使って、迅速にYAMLを生成すること
- `labels`や`serviceAccountName`など、必要なフィールドを確実に追加すること
- Podが正常に起動し、RBAC設定が正しく適用されていることを確認すること
- コンテナ内で実際に操作を行い、RBAC設定を検証すること

---

これで、**RBAC** と **ServiceAccount** を使用した設定が完了し、**Pod** の権限を制御する方法を確認できました。この設定を使って、試験と実務で役立つセキュリティ設計を学ぶことができます。