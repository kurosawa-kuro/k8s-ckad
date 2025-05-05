以下は、**パブリックのbusybox**イメージを使用した、**SecurityContext**の設定に関する正解のYAMLです。

---

✅ イメージで理解：数字の意味を名前に例えると

数字	実際の意味（たとえ）
uid=0	Linuxのroot（＝神様ユーザー）
uid=1000	appuser 的な非特権ユーザー
fsGroup=2000	appgroup 的な共有グループ
✅ まとめ：あなたが覚えておけばいいのはこれだけ！

フィールド名	意味	よく使う値
runAsUser	実行ユーザーUID	1000（非root）
runAsNonRoot	root禁止を強制	true
fsGroup	ファイルアクセス用のグループID	2000（共有書き込み用）

### 初期YAML生成コマンド

まず、`kubectl run`を使ってYAMLの初期テンプレートを生成します。

```bash
kubectl run secure-pod --image=busybox --dry-run=client -o yaml -- sleep 3600 > secure-pod.yaml
```

---

### 修正後の正解YAML（`secure-pod.yaml`）

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  labels:
    app: secure-app  # 明確なラベルを設定
spec:
  securityContext:
    runAsUser: 1000         # 非rootユーザーでPod全体を実行
    fsGroup: 2000           # ファイルアクセスのグループ権限を設定
  containers:
  - name: secure-pod
    image: busybox
    command: ["sleep", "3600"]
    securityContext:
      runAsNonRoot: true                # rootとして実行しない
      readOnlyRootFilesystem: true      # ルートファイルシステムを読み取り専用に
      capabilities:
        drop: ["NET_RAW"]              # 特定のLinuxケーパビリティを無効化
```

---

### 重要なポイント

- **`runAsUser`**: Pod内のプロセスが非rootユーザー（ID 1000）として実行されるように設定しています。これにより、セキュリティを強化できます。
- **`fsGroup`**: Pod内でファイルアクセスを行うグループのIDを設定します。この設定は、ファイルシステムのアクセス権を制御します。
- **`runAsNonRoot`**: コンテナ内でrootユーザーとして実行されないように設定しています。
- **`readOnlyRootFilesystem`**: ルートファイルシステムを読み取り専用に設定し、書き込み攻撃を防ぎます。
- **`capabilities`**: `NET_RAW`などの特定のLinuxケーパビリティを無効化し、不要な特権の使用を制限しています。

---

### 動作確認手順

1. **Podの作成**

```bash
kubectl apply -f secure-pod.yaml
```

2. **Podの状態確認**

```bash
kubectl get pods
kubectl describe pod secure-pod
```

3. **コンテナ内でのユーザー確認**

```bash
kubectl exec secure-pod -- id
```

- 結果に`uid=1000`が表示されれば成功です。

4. **ルートファイルシステムの確認**

```bash
kubectl exec secure-pod -- touch /testfile
```

- 読み取り専用のエラーが出れば成功です。

---

### CKAD試験の重要なポイント

- `kubectl create`や`kubectl run`を使用して迅速にYAMLを生成し、最低限の変更で作成します。
- `labels`と`securityContext`を明確に設定することが求められます。
- Podが`Running`状態になることを必ず確認し、セキュリティ設定が意図通りに動作しているか検証します。
- 作業のスピードと正確性がCKAD試験の合格のカギです。

---

このYAMLで`SecurityContext`の基本的な設定を確認・適用できます。