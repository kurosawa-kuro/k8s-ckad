# CKAD 一言解説チートシート

> **目的**: 2 時間試験中に “キーワードの役割” を即リマインドできる最小メモ。
> 
> **フォーマット**: 「カテゴリ ➜ キーワード ➜ 1 行説明」

## 1. Workloads & Pod Design

| キーワード                               | 一言説明                                          |
| ----------------------------------- | --------------------------------------------- |
| Deployment / ReplicaSet             | 宣言的ローリング更新の中核リソース                             |
| StatefulSet                         | 順序・永続 ID が必要なステートフル Pod 用                     |
| Job / CronJob                       | 1 回 / 定期バッチ。`parallelism` と `completions` を暗記 |
| initContainers                      | 本体 Pod 起動前に準備を 1 度だけ実行                        |
| sidecar                             | 同じ Pod 内で常駐しメインを補助するコンテナ                      |
| probes (liveness/readiness/startup) | 再起動・負荷分散判定・起動遅延対策                             |
| terminationGracePeriodSeconds       | SIGTERM→待機→SIGKILL の秒数                        |

## 2. Scheduling & Placement

| キーワード                      | 一言説明                                   |
| -------------------------- | -------------------------------------- |
| nodeSelector               | 単純ラベル一致でノード固定                          |
| nodeAffinity / podAffinity | `required`=必須, `preferred`=希望配置        |
| taints / tolerations       | ノードを避ける印 → Pod が許可札(toleration)を持てば配置可 |
| topologySpreadConstraints  | ラベル単位で Pod を均等分散                       |

## 3. Configuration & Secrets

|キーワード|一言説明|
|---|---|
|ConfigMap|文字列設定をキー/値で Pod へ注入|
|Secret|Base64 で格納される機密データ │|
|envFrom / valueFrom|CM/Secret を一括 / 個別で環境変数化|
|downwardAPI|Pod 自身のメタ情報を注入 (`metadata.name` 等)|

## 4. Service & Networking

| キーワード                                | 一言説明                       |
| ------------------------------------ | -------------------------- |
| ClusterIP / NodePort / LoadBalancer  | 内部 / ノード固定ポート / クラウド LB 公開 |
| Headless Service (`clusterIP: None`) | SRV レコードのみ、ロードバランサしない      |
| ExternalName                         | 内部 DNS CNAME だけ作成          |
| Ingress (path, backend)              | URL → Service ルーティングエントリ   |
| NetworkPolicy (`Ingress` / `Egress`) | ラベルで通信許可をホワイトリスト定義         |

## 5. Storage

|キーワード|一言説明|
|---|---|
|PVC / PV|要求と実体を分離して永続ボリューム確保|
|StorageClass (`provisioner`)|動的 PV を作るドライバ種類|
|accessModes (`RWO`,`RWX`)|同時マウント可否 (`ReadWriteOncePod` も)|
|reclaimPolicy (`Retain`)|PVC 削除後も PV/データ残す|
|emptyDir|Pod ライフタイム限定の一時ディスク|

## 6. Security

| キーワード                      | 一言説明                                                            |
| -------------------------- | --------------------------------------------------------------- |
| **SecurityContext**        | Pod/Container の UID・capability 等を宣言的に設定（Container が Pod 設定より優先） |
| runAsNonRoot / runAsUser   | 非 root 強制 / UID を固定                                             |
| allowPrivilegeEscalation   | `sudo/setuid` で root 昇格を許可するか                                   |
| capabilities (add/drop)    | Linux カーネル権限を最小化 (`NET_ADMIN` 等)                                |
| ServiceAccount / RBAC Role | Pod に API 権限を与える ID とロール定義                                      |

## 7. Observability & Debug

|キーワード|一言説明|
|---|---|
|kubectl logs / exec / describe|ログ確認 / その場 bash / 詳細＆Events 見る三種の神器|
|kubectl top pod / node|Metrics Server 由来の CPU/メモリ瞬時表示|

---

### 使い方ヒント

- 試験前に **カテゴリごとに YAML を 3 例ずつ** 手書き→`kubectl apply` で身体に落とす。
    
- 本番は `kubectl explain <resource>.<field>` TAB 補完を多用してスピード確保。