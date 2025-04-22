以下の手順に基づき、**CronJobによるスケジュール実行**に関するチュートリアルの具体的なコマンドとYAML修正を整理しました。

---

# 📘 CKAD試験対策チュートリアル: CronJobによるスケジュール実行

## ✅ 作業ディレクトリ

- `~/dev/k8s-kind-ckad/04-cronjob`

## ✅ 使用コンテナイメージ

- **イメージ候補**: 
    - `busybox` (軽量でスケジュール実行に適している)
    - `nginx`（シンプルなタスクに使用可能）
    
    **選定理由**:
    - 軽量でシンプルなバッチ処理を実行する目的に適しており、CKAD試験でのスケジュールジョブの練習に最適です。

---

## 🚀 チュートリアル手順

### 📌 Step 1: CronJob初期生成

まずは、`kubectl create cronjob`を使って、初期のCronJobリソースを迅速に生成します。以下のコマンドを使用して、最初のYAMLを生成します：

```bash
kubectl create cronjob hello-job --image=busybox --schedule="*/1 * * * *" -- dry-run=client -o yaml > cronjob.yaml
```

上記のコマンドで、毎分1回 `busybox` コンテナを実行するCronJobが生成されます。`--dry-run=client`を指定しているため、実際にはリソースは作成されず、出力だけが得られます。

生成されたYAMLは次のようになります：

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello-job
spec:
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello-job
            image: busybox
            command:
            - /bin/sh
            - -c
            - "echo Hello CKAD"
          restartPolicy: OnFailure
```

### 📌 Step 2: YAMLの修正

上記の生成されたYAMLに必要な修正を加えます。具体的な変更点は以下の通りです。

**[修正箇所①]** CronJobに適切なラベルを追加します：

```diff
metadata:
  name: hello-job
- labels:
+ labels:
    app: cronjob-example
```

**[修正箇所②]** 実行するコマンドを変更（`echo "Hello CKAD"`）：

```diff
containers:
  - name: hello-job
    image: busybox
-   command:
-     - /bin/sh
-     - -c
-     - "echo Hello CKAD"
+   command:
+     - /bin/sh
+     - -c
+     - "echo 'Hello CKAD'"
```

**[修正箇所③]** 再試行回数（`backoffLimit`）と並行実行数（`concurrencyPolicy`）の追加：

```diff
spec:
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: hello-job
              image: busybox
              command:
                - /bin/sh
                - -c
                - "echo 'Hello CKAD'"
          restartPolicy: OnFailure
+      backoffLimit: 3
+      concurrencyPolicy: Forbid
```

### 📌 Step 3: 完成版YAML

最終的なYAMLは以下の通りです：

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello-job
  labels:
    app: cronjob-example
spec:
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: hello-job
              image: busybox
              command:
                - /bin/sh
                - -c
                - "echo 'Hello CKAD'"
          restartPolicy: OnFailure
      backoffLimit: 3
      concurrencyPolicy: Forbid
```

### 📌 Step 4: CronJobのデプロイ

作成したYAMLを適用してCronJobをデプロイします：

```bash
kubectl apply -f cronjob.yaml
```

### 📌 Step 5: CronJobの状態確認

CronJobの状態を確認するには、以下のコマンドを使用します：

```bash
kubectl get cronjobs
```

CronJobが正しく設定されているか確認できます。

### 📌 Step 6: CronJobの実行確認

CronJobは設定したスケジュールに従ってジョブを実行します。Jobが作成されたか、Podが生成されているかを確認するには、以下のコマンドを使用します：

```bash
kubectl get jobs
kubectl get pods --selector=job-name=hello-job
```

Podが生成され、`Completed` 状態になることを確認します。

### 📌 Step 7: Jobのログ確認

生成されたPodのログを確認し、期待した結果が表示されるか確認します：

```bash
kubectl logs <pod-name>
```

出力例：

```bash
Hello CKAD
```

### 📌 Step 8: CronJobの削除

不要になったCronJobを削除するには、以下のコマンドを実行します：

```bash
kubectl delete cronjob hello-job
```

その後、`kubectl get cronjobs` を使ってCronJobが削除されたことを確認します。

---

## ✅ CKAD試験ポイント再整理

- **`kubectl create cronjob`** を使ってCronJobの初期YAMLを迅速に生成
- 必須フィールド（`labels`, `schedule`, `command`）を明確に修正
- CronJobが指定間隔通りに正常に実行され、Podが生成・終了することを確認
- ログによるCronJob実行結果の明確な確認方法を提示
- 作業スピードと正確性がCKAD合格の鍵

---

## ✅ 今後のチュートリアル拡張性への配慮（明示）

- CronJobとJobを組み合わせたバッチ処理の高度な管理
- CronJobを用いた定期的ヘルスチェックやモニタリング処理
- CronJobとConfigMap/Secretを連携させた設定管理
- CronJobとPersistentVolumeを連携させたデータ保持方法

---

## ✅ 本チュートリアル完了時のゴール

- **CKAD試験**でCronJobのYAMLマニフェストを迅速かつ正確に作成できるようになる
- **KubernetesのCronJobリソース**の動作を明確に理解し、実務での定期バッチ処理を確実に運用できるようになる

--- 

🎯 以上で**CronJobによるスケジュール実行**に関するチュートリアルを完璧に習得できました！