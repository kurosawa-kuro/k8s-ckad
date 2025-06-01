# CKAD Job / CronJob 速習ノート

## 1. コントローラ階層と主要フィールドの置き場所

```
CronJob (batch/v1)
└─ spec                     # CronJob レベル
   ├─ schedule                # 必須 Cron 表記
   ├─ startingDeadlineSeconds # “どれだけ遅延を許すか”
   ├─ concurrencyPolicy       # Allow | Forbid | Replace
   ├─ successfulJobsHistoryLimit / failedJobsHistoryLimit
   ├─ suspend                 # true で一時停止
   └─ jobTemplate             # === Job の世界へ ===
      └─ spec                 # JobSpec
         ├─ completions / parallelism
         ├─ backoffLimit
         ├─ activeDeadlineSeconds
         ├─ ttlSecondsAfterFinished
         └─ template          # === Pod の世界へ ===
            └─ spec           # PodSpec
               └─ containers / ...
```

| 用途       | Job 直下 (`job.spec`)       | CronJob 直下 (`cronjob.spec`)       | CronJob JobSpec (`cronjob.spec.jobTemplate.spec`) |
| -------- | ------------------------- | --------------------------------- | ------------------------------------------------- |
| 実行回数・並列数 | completions / parallelism | ―                                 | completions / parallelism                         |
| リトライ上限   | backoffLimit              | ―                                 | backoffLimit                                      |
| 実行時間上限   | activeDeadlineSeconds     | ―                                 | activeDeadlineSeconds                             |
| 終了後 GC   | ttlSecondsAfterFinished   | ―                                 | ttlSecondsAfterFinished                           |
| スケジュール   | ―                         | schedule                          | ―                                                 |
| 遅延許容     | ―                         | startingDeadlineSeconds           | ―                                                 |
| 同時実行ポリシー | ―                         | concurrencyPolicy                 | ―                                                 |
| 履歴保持数    | ―                         | successful/failedJobsHistoryLimit | ―                                                 |
| 一時停止     | ―                         | suspend                           | ―                                                 |

> **暗記フレーズ**
> *Cron = 時計、Job = 回数、Pod = タイマー*

## 2. 最小 YAML スニペット

### (A) 単発 Job

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: one-shot
spec:
  completions: 1            # デフォルト 1
  parallelism: 1           # デフォルト 1
  backoffLimit: 2
  activeDeadlineSeconds: 60
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: busybox
        image: busybox
        command: ["sh","-c","echo CKAD && sleep 40"]
```

### (B) 5 分ごとの CronJob（30 秒タイムアウト）

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: every-five
spec:
  schedule: "*/5 * * * *"
  startingDeadlineSeconds: 20
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      activeDeadlineSeconds: 30
      ttlSecondsAfterFinished: 60
      template:
        spec:
          restartPolicy: Never
          containers:
          - name: hello
            image: busybox
            command: ["echo","hello-from-cron"]
```

## 3. CLI ワンライナー集

| ゴール                       | コマンド                                                                                |
| ------------------------- | ----------------------------------------------------------------------------------- |
| busybox で 1 回だけ `date` 実行 | `kubectl create job date --image=busybox -- date`                                   |
| スケジュール付き CronJob 雛形       | `kubectl create cronjob mycron --image=busybox --schedule="*/2 * * * *" -- echo hi` |
| Job にタイムアウト追加             | `kubectl patch job date -p '{"spec":{"activeDeadlineSeconds":15}}' --type=merge`    |
| CronJob を一時停止             | `kubectl patch cronjob mycron -p '{"spec":{"suspend":true}}' --type=merge`          |

## 4. よくある落とし穴チェックリスト

* **CronJob に `activeDeadlineSeconds` を書く場所** → 必ず `jobTemplate.spec`。
* **`restartPolicy`** → Job/CronJob では `Never` または `OnFailure` のみ。
* **`startingDeadlineSeconds` vs `activeDeadlineSeconds`**
  遅延許容か実行時間上限か、混同しない。
* **履歴保持数** → 不要なら `successfulJobsHistoryLimit: 0` で即削除。
* **並列完了型** → `completions` と `parallelism` 両指定問題に注意。

---

これ一枚で CKAD の Job / CronJob の設問は大半カバーできます。
