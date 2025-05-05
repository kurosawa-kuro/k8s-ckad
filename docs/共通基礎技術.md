| Pod / Deployment   | ◎（必ず出る） | ✅ 構文が身体に入っている |
| ConfigMap / env  / Secret  | ◎      | ✅ よく出るしミスしにくい |
| Volume /Volume Mount/ PV / PVC       | ◎      | ✅ 実装再現できるなら確実に拾える |
| Service / ClusterIP / Node| ◎      | ✅ ルーティング問題は点が取りやすい |

| Job / CろｎJob


関係図

kubectl explain po --recursive | grep volume
kubectl api-resources | grep volume

kubectl explain ConfigMap
kubectl explain Secret
kubectl explain po --recursive | grep securityContext
kubectl explain deploy --recursive | grep securityContext