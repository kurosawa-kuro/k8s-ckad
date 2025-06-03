# CKAD 本番で“パッと効く”ワンポイント集

| カテゴリ                   | ワンポイント                                                                                     | 補足ワード／コマンド例                                                |
| ---------------------- | ------------------------------------------------------------------------------------------ | ---------------------------------------------------------- |
| **Service ↔︎ Pod 接続**  | **Pod が見つからない = 99 % は `selector` と `labels`、または `targetPort` と `containerPort` の不一致**     | `kubectl describe svc <svc>` で `Endpoints:` が空かどうか即確認      |
|                        | **修正は Service 側 (`targetPort`) を合わせる方が安全**                                                 | Pod を再デプロイせずに済み、時間短縮                                       |
| **Deployment ロールバック**  | **履歴 → ロールバック → 状態確認** を 3 連発 alias 化して 1 分短縮                                              | see alias block below                                      |
|                        | **失敗理由を 1 行で書けば減点ゼロ**                                                                      | 例: `イメージ nginx:9.99‑does‑not‑exist が存在せず ImagePullBackOff` |
| **Pod & コンテナ健全性**      | **readinessProbe / livenessProbe は “失敗から逆算”** — まず `kubectl describe pod` で Probe の失敗ログを確認 | `initialDelaySeconds` と `periodSeconds` を調整して復旧            |
| **InitContainer**      | **必要ファイルを Init で先に配置し 404 を防止**                                                            | 共有ボリュームに `echo` / `touch` で用意                              |
| **Secret / ConfigMap** | **環境変数 vs ボリュームを混同しない**<br>– 文字列は `env`, `envFrom`<br>– ファイルは `volumeMounts`               | Secret → `Opaque` + `stringData`; ConfigMap → `items:`     |
| **ストレージ**              | **問題文に “storageClassName は設定しない” とあったら空欄必須**                                               | デフォルト SC を入れてバインド失敗しがち                                     |
| **NodePort 試験**        | **`kubectl get nodes -o wide` → 内部 IP & 指定ポートで `curl`**                                    | 試験環境は外部 IP が無効な場合あり                                        |
| **NetworkPolicy**      | **egress で API 先だけ許可、DNS は 53/TCP & 53/UDP を忘れずに許可**                                       | `ports:` ブロックを 2 つ書くと覚える                                   |
| **タイムマネジメント**          | **“先に create → その場で編集” が最速**<br>`-o yaml --dry-run=client > file.yaml` で雛形生成               | 難問は一旦スキップ、最後に戻る                                            |

---

## ロールバック alias 例

```bash
alias k=kubectl
# Deployment 履歴
alias rho='k -n <ns> rollout history deploy/<name>'
# 任意のリビジョンへロールバック
alias rro='k -n <ns> rollout undo deploy/<name> --to-revision=<rev>'
# 状態確認
alias rrs='k -n <ns> rollout status deploy/<name>'
```

> これだけ頭に入れておけば、試験中に「どこから手を付けるか」で迷う時間がほぼゼロになります。健闘を祈っています💪
