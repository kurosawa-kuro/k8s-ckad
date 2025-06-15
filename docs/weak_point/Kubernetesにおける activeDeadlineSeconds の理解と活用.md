以下に、`activeDeadlineSeconds` の理解と試験対策に特化した技術ドキュメントとしてまとめました。

---

# 📘 Kubernetesにおける `activeDeadlineSeconds` の理解と活用

## 概要

`activeDeadlineSeconds` は Kubernetes の `Pod` または `Job` の `.spec` フィールドに定義される **最大実行時間制限** です。指定した秒数を超えても完了しない場合、Kubernetes によって **Pod は強制終了**されます。

---

## 使用目的

* **無限ループや実行時間の長いPodの強制制限**
* **Jobが一定時間内に終了しないことへの対処**
* **リソース消費の抑制**
* **試験（CKAD）における典型的な制限設定**

---

## 設定可能なリソースと位置

| リソース種類 | 記述場所                         | 構文例                              |
| ------ | ---------------------------- | -------------------------------- |
| Pod    | `spec.activeDeadlineSeconds` | `spec.activeDeadlineSeconds: 30` |
| Job    | `spec.activeDeadlineSeconds` | `spec.activeDeadlineSeconds: 60` |

---

## YAML例

### ✅ Podでの使用例

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: timeout-demo
spec:
  activeDeadlineSeconds: 20
  containers:
  - name: sleeper
    image: busybox
    command: ["sleep", "3600"]
```

---

### ✅ Jobでの使用例

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: timeout-job
spec:
  activeDeadlineSeconds: 30
  template:
    spec:
      containers:
      - name: sleeper
        image: busybox
        command: ["sleep", "3600"]
      restartPolicy: Never
```

---

## 動作仕様

* `activeDeadlineSeconds` に到達した時点で、**Podは`Failed`状態**になります。
* Jobに対して設定した場合、**Jobに紐づくPodが対象**となり、Job自体も `Failed` 状態になります。
* cronJob の `.jobTemplate.spec` にも同様に指定可能。

---

## よくある誤解と注意点

| 誤解                                           | 実際の挙動                                                            |
| -------------------------------------------- | ---------------------------------------------------------------- |
| `containers[].activeDeadlineSeconds` に書いてしまう | ❌ 認識されません。PodやJobの `spec` の直下に書く必要があります                          |
| `CronJob.spec` に書けると思っている                    | ❌ CronJobでは `.jobTemplate.spec.activeDeadlineSeconds` に書く必要があります |
| `timeoutSeconds` などと混同                       | ❌ `livenessProbe.timeoutSeconds` とは全く別物です                        |

---

## CKAD試験対策視点

* **出題頻度：★★★☆☆（中程度〜高め）**
* 問題文に「〇〇秒以内に完了しなければならないPod/Jobを作成せよ」とあれば、まずこのフィールドを疑うべき。
* 他のタイムアウト系（`backoffLimit`, `ttlSecondsAfterFinished`）との違いを明確に。

---

## 比較表：似たようなパラメータとの違い

| パラメータ                        | 目的               | 対象      | 設定場所                              |
| ---------------------------- | ---------------- | ------- | --------------------------------- |
| `activeDeadlineSeconds`      | **実行時間の上限**      | Pod/Job | `spec`                            |
| `backoffLimit`               | 失敗時の再試行上限        | Job     | `spec.backoffLimit`               |
| `ttlSecondsAfterFinished`    | Job完了後の自動削除までの時間 | Job     | `spec.ttlSecondsAfterFinished`    |
| `successfulJobsHistoryLimit` | CronJobの成功履歴保持件数 | CronJob | `spec.successfulJobsHistoryLimit` |

---

## 参考リンク

* [公式ドキュメント: Podの構成](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-phase)
* [公式ドキュメント: Job](https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-backoff-failure-policy)
* [公式ドキュメント: CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)

---

## まとめ

* `activeDeadlineSeconds` は **実行時間制限** を与える重要な制御フィールド。
* 試験でも実務でも、**PodやJobの暴走対策**として使用される。
* **構造が深くない分、書き場所を間違えやすいため注意が必要**。

---

ご希望があれば、`.md` や `.yaml` テンプレ形式での出力、または `cronjob` における応用パターンもご提供できます。
