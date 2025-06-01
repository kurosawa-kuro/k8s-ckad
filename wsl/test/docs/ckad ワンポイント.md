CKAD 的ワンポイント
「Service が Pod を見つけられない」＝ 99 % は selector ↔ labels か targetPort ↔ containerPort の不一致
まずは kubectl describe svc で Endpoints が空かどうか確認すると早いです。

ポート番号は Pod 側をいじるより Service の targetPort を合わせる方が低リスク。
Deployment をロールアウトし直す時間も節約できます。

CKAD 本番で役立つワンポイント
ロールバック手順

bash
コピーする
編集する
kubectl -n <ns> rollout history deploy/<name>
kubectl -n <ns> rollout undo deploy/<name> --to-revision=<rev>
kubectl -n <ns> rollout status deploy/<name>
この 3 連発を alias 化しておくと 1 分短縮できます。

失敗原因の報告
「イメージ nginx:9.99-does-not-exist が存在せず ImagePullBackOff」
という 1 行を書ければ減点されません。

