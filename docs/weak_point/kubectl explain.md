下の表に **“覚えづらい／頻出なのに深い階層にある” フィールド** をぜんぶ一枚に統合しました。  
✅ 印は **CKAD で特に狙われやすい** もの、★印は **追加依頼で補完した項目** です。  
コピペして `kubectl explain …` すれば即ドキュメントへ飛べます。

| カテゴリ                         | 見たいフィールド                    | explain ワンライナー                                                                 | 覚えどころ                                     |
| ---------------------------- | --------------------------- | ------------------------------------------------------------------------------ | ----------------------------------------- |
| **🛡 Security & RBAC**       | SecurityContext ✅           | `kubectl explain pod.spec.containers.securityContext.allowPrivilegeEscalation` | デフォルト `true`。CKA/CKS では `false` 推奨        |
|                              | Capabilities ✅              | `kubectl explain pod.spec.containers.securityContext.capabilities.add`         | `add:` / `drop:` が兄弟                      |
|                              | ServiceAccountName★         | `kubectl explain pod.spec.serviceAccountName`                                  | 省略時は `<default>` が入る                      |
| **🔧 Env / Config / Secret** | Env 配列                      | `kubectl explain pod.spec.containers.env`                                      | 配列なので `- name:` で始める                      |
|                              | ConfigMap as Volume★        | `kubectl explain pod.spec.volumes.configMap`                                   | `items:` でキー→ファイル名                        |
|                              | ConfigMap as Env★           | `kubectl explain pod.spec.containers.env.valueFrom.configMapKeyRef`            | 単キーは KeyRef／丸ごとは `envFrom.configMapRef`   |
|                              | Secret as Volume★           | `kubectl explain pod.spec.volumes.secret`                                      | `defaultMode:` 0400→0644 など               |
|                              | Secret as Env★              | `kubectl explain pod.spec.containers.env.valueFrom.secretKeyRef`               | `.data.*` は Base64                        |
| **🚑 Health Checks**         | LivenessProbe★              | `kubectl explain pod.spec.containers.livenessProbe`                            | NG で **Pod 再起動**                          |
|                              | ReadinessProbe★             | `kubectl explain pod.spec.containers.readinessProbe`                           | 未 Ready は **Service 除外**                  |
|                              | StartupProbe★               | `kubectl explain pod.spec.containers.startupProbe`                             | 起動完了判定→成功後は Live/Ready 有効                 |
| **📦 Workloads**             | RollingUpdate ✅             | `kubectl explain deployment.spec.strategy.rollingUpdate`                       | `maxSurge` / `maxUnavailable`             |
| **🌐 Networking & Service**  | Service.targetPort ✅        | `kubectl explain service.spec.ports.targetPort`                                | `port` ↔ `targetPort` の混同注意               |
|                              | Service.type★               | `kubectl explain service.spec.type`                                            | `ClusterIP` / `NodePort` / `LoadBalancer` |
|                              | NodePort 番号★                | `kubectl explain service.spec.ports.nodePort`                                  | 空なら 30000-32767 で自動割当て                    |
|                              | Ingress backend (v1)        | `kubectl explain ingress.spec.rules.http.paths.backend.service`                | `service.name` / `service.port`           |
| **🔒 NetworkPolicy**         | policyTypes ✅               | `kubectl explain networkpolicy.spec.policyTypes`                               | `Ingress`, `Egress`／省略時 All               |
|                              | egress ✅                    | `kubectl explain networkpolicy.spec.egress`                                    | `to:` と `ports:` を同階層で                    |
| **🗄 Storage**               | PVC.storageClassName ✅      | `kubectl explain pvc.spec.storageClassName`                                    | `""` で SC を使わない宣言                         |
|                              | PV.reclaimPolicy★           | `kubectl explain persistentvolume.spec.persistentVolumeReclaimPolicy`          | `Retain` / `Delete` / `Recycle(旧)`        |
|                              | StorageClass.reclaimPolicy★ | `kubectl explain storageclass.reclaimPolicy`                                   | SC 側で既存 PV の挙動を上書き                        |
| **⏱ Jobs & CronJobs**        | Job.activeDeadlineSeconds   | `kubectl explain job.spec.activeDeadlineSeconds`                               | Job 全体のタイムアウト                             |
|                              | CronJob.history ★           | `kubectl explain cronjob.spec.successfulJobsHistoryLimit`                      | `failedJobsHistoryLimit` とペア              |
| **⚖️ LimitRange**            | default / defaultRequest    | `kubectl explain limitrange.spec.limits.default`                               | `defaultRequest` も兄弟キー                    |

---

### ３手順で“指が勝手に動く”ようにする

1. **TAB 補完でパスを体に覚えさせる**
    
    ```bash
    kubectl explain pod.spec.containers.sec<TAB>.allowP<TAB>
    ```
    
2. **重要スニペットを自作ファイルに**  
    例：`snip/probe.yaml`、`snip/sa.yaml` … → `k apply -f` → `k describe`。
    
3. **grep で要点だけ読む**
    
    ```bash
    k explain pod.spec.containers.livenessProbe | grep -A2 description
    ```
    

> これさえあれば試験中に“あの階層なんだっけ？”と迷っても即復旧できます。  
> ほかに追加したいフィールドがあれば気軽にどうぞ！