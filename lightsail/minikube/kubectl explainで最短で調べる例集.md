# kubectl explain 最短チートシート (CKAD対応)

※ CKAD試験中にすぐ使えるように「コマンドとパス」の形にしてあります。

---

# kubectl explain 例集（チュートリアル順）

| チュートリアルテーマ | 推奨イメージ | 調べるべきフィールド | kubectl explainコマンド例 |
|:---|:---|:---|:---|
| Pod基礎 | nginx / busybox | Pod基本構成 | kubectl explain pod |
| マルチコンテナPod（サイドカー） | express + busybox | containersフィールド | kubectl explain pod.spec.containers |
| Job | busybox | Job基本構成 | kubectl explain job |
| CronJob | busybox / express | scheduleフィールド | kubectl explain cronjob.spec.schedule |
| ConfigMap / Secret | express | envFrom設定方法 | kubectl explain pod.spec.containers.envFrom |
| Probe（Liveness / Readiness） | express | livenessProbe, readinessProbe | kubectl explain pod.spec.containers.livenessProbe |
| Volume / PVC | express | volumes, volumeMounts | kubectl explain pod.spec.volumes / kubectl explain pod.spec.containers.volumeMounts |
| Service / Ingress | express | service.spec, ingress.spec | kubectl explain service.spec / kubectl explain ingress.spec |
| NetworkPolicy | express + busybox | ingress, egress設定 | kubectl explain networkpolicy.spec.ingress |
| SecurityContext（ユーザー確認） | busybox | securityContext | kubectl explain pod.spec.containers.securityContext |
| RBAC（get podsテスト） | bitnami/kubectl | Role, RoleBinding基本 | kubectl explain role / kubectl explain rolebinding |
| ログ / exec / debug | express | 特になし（kubectl logs / exec） | - |

---

# 【Tips】
- 誰でも思い出せるように「なんのために調べるか」を意識して使う
- "explain" の後は 「リソース名」「.spec」「.spec.template.spec」 のように通常いう
- CKADは少しでも調べてよい試験だから、早くkubectl explainに持ち込むこと

もっと増やしたり、スマホリ用に修羅も可能です🚀

