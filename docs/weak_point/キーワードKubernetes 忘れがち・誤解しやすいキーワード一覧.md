# Kubernetes 忘れがち・誤解しやすいキーワード一覧

| カテゴリ                  | キーワード                                      | 誤解ポイント・注意点 (一言)                     |
| --------------------- | ------------------------------------------ | ----------------------------------- |
| **スケジューリング & アフィニティ** | taints / tolerations                       | Node 側(Taint)とPod側(Toleration)の向きが逆 |
|                       | nodeSelector                               | 単純なラベル一致。Affinity と排他使用に注意          |
|                       | nodeAffinity / preferredDuringScheduling   | ソフト/ハード要件、語順が紛らわしい                  |
|                       | podAffinity / podAntiAffinity              | 相互参照ラベルが必要で失敗しやすい                   |
|                       | topologySpreadConstraints                  | minDomains の書き方を忘れがち                |
| **Pod ライフサイクル**       | terminationGracePeriodSeconds              | SIGTERM→猶予→SIGKILL フローを理解           |
|                       | preStop / postStart hooks                  | exec / HTTP / TCP 3 種類              |
|                       | finalizers                                 | ゴミリソース残存の主因、手動削除が必要                 |
|                       | ownerReferences                            | cascade delete の鍵、namespace 跨ぎ不可    |
| **可用性 & 自動化**         | PodDisruptionBudget (PDB)                  | drain が止まる原因 No.1                   |
|                       | HorizontalPodAutoscaler (HPA)              | metrics.k8s.io が無いと動かない             |
|                       | VerticalPodAutoscaler (VPA)                | updateMode=Off が既定で効かない             |
|                       | ResourceQuota vs LimitRange                | 名前が似て役割を混同しやすい                      |
| **ネットワーク & サービス**     | Headless Service (`clusterIP: None`)       | SRV レコード生成、ロードバランスしない               |
|                       | ExternalName                               | CNAME だけ作り Pod とは接続しない              |
|                       | EndpointSlice                              | v1.21 以降デフォルト、手動操作は plural 名        |
|                       | targetPort vs containerPort                | Service と Pod 定義を混同しがち              |
| **セキュリティ**            | PodSecurityAdmission (baseline/restricted) | PSP 廃止後の標準、Namespace ラベルで制御         |
|                       | seccompProfile                             | RuntimeDefault が推奨、指定忘れが多い          |
|                       | runAsNonRoot                               | UID=0 イメージでエラーに注意                   |
|                       | fsGroup / fsGroupChangePolicy              | RWX ボリュームに必須の場合あり                   |
|                       | sysctls / safeSysctls                      | 許可プレフィックスに注意                        |
|                       | runtimeClassName                           | gVisor など Sandbox ランタイム切替           |
| **ストレージ**             | CSIDriver / CSINode                        | 動的プロビジョンまでに両方必要                     |
|                       | VolumeSnapshot / VolumeSnapshotClass       | Alpha→Beta→GA で APIVersion が変遷      |
|                       | reclaimPolicy `Delete` vs `Retain`         | PV 消失 or ゴミ残りの分岐点                   |
| **API拡張 & Webhook**   | CustomResourceDefinition (CRD) versions    | v1beta1 → v1 変換Webhook 必要           |
|                       | ValidatingAdmissionWebhook / Policy        | v1.26+ の Policy API が混在             |
|                       | Aggregated API (`APIService`)              | 443 以外ポートは認証に注意                     |
| **ノード管理**             | taint-based eviction                       | メモリ/ディスク圧迫で自動付与                     |
|                       | `kubectl drain` vs `cordon`                | 排出と受付停止の違い                          |
|                       | etcd snapshot / restore                    | CKA 出題常連、証明書とパスに注意                  |
＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝

# CKAD 忘れがち・誤解しやすいキーワード一覧

> **対象範囲**: CKAD (v1.32) シラバスに出題される可能性が高い項目だけを厳選しています。

| カテゴリ                      | キーワード                                            | 誤解ポイント・注意点 (一言)                                                          |
| ------------------------- | ------------------------------------------------ | ------------------------------------------------------------------------ |
| **スケジューリング & アフィニティ**     | taints / tolerations                             | Node 側(Taint)と Pod 側(Toleration)の向きが逆。`NoSchedule` と `NoExecute` を混同しやすい |
|                           | nodeSelector                                     | 単純なラベル一致。Affinity と併用すると override されないので注意                               |
|                           | nodeAffinity / preferredDuringScheduling         | required と preferred の語順が紛らわしい (硬/軟条件)                                   |
|                           | podAffinity / podAntiAffinity                    | 相互参照ラベルが必要。namespaceSelector の併用を忘れがち                                    |
|                           | topologySpreadConstraints                        | `maxSkew` と `whenUnsatisfiable` の組み合わせを暗記                                |
| **Pod デザイン & ライフサイクル**    | sidecar                                          | 同一 Pod 内でメインを補助。終了順序 (PreStop→Main→Sidecar) に注意                          |
|                           | initContainers                                   | 本体コンテナ起動前に 1 回だけ実行。リソース制限は container と同形で書く                              |
|                           | liveness / readiness / startup probes            | HTTP/Exec/TCP の 3 方式。失敗時の挙動がそれぞれ違う                                       |
|                           | terminationGracePeriodSeconds                    | SIGTERM → 猶予 → SIGKILL の秒数。無限ループで stuck しやすい                             |
|                           | preStop / postStart hooks                        | `exec` / `httpGet` / `tcpSocket` の違い                                     |
| **Configuration**         | ConfigMap / Secret                               | `envFrom`✦一括、`valueFrom`✦個別注入。Secret は base64 で忘れがち                      |
|                           | downwardAPI                                      | Pod 自身の `metadata.name` などを環境変数へ注入                                       |
|                           | serviceAccountName                               | Pod に紐付くアイデンティティ。省略時 default SA が付与される                                   |
| **Services & Networking** | ServiceType: ClusterIP / NodePort / LoadBalancer | 内部 / ポート固定公開 / クラウド LB。`targetPort` と `containerPort` を混同しがち             |
|                           | Headless Service (`clusterIP: None`)             | SRV レコード生成、EndPoints に IP 群を直接返す                                         |
|                           | ExternalName                                     | CNAME 作成のみでロードバランスしない (Pod 経由しない)                                        |
|                           | Ingress (basic)                                  | `path` + `serviceName:port`。`pathType: Prefix` が既定ではない Controller もある    |
| **State Persistence**     | PVC / PV                                         | 使う(Claim) と提供する(Volume) を分離。容量は PVC で要求                                  |
|                           | storageClassName                                 | 動的プロビジョニングに必須。空欄なら既定の StorageClass                                       |
|                           | accessModes                                      | RWO/RWX/ROX の組合せを暗記 (`ReadWriteOncePod` は 1.22+)                         |
|                           | reclaimPolicy (`Retain` / `Delete`)              | データ保持 or 破棄。試験でよく罠になる                                                    |
|                           | emptyDir                                         | Pod ライフサイクル限定の一時ディスク。Medium=Memory にできる                                  |
| **Observability & デバッグ**  | `kubectl logs -f`                                | `--tail`, `--since` オプションを活用                                             |
|                           | `kubectl exec -it`                               | シェルが無い Alpine イメージで失敗しやすい (`/bin/sh`)                                    |
|                           | `kubectl describe <pod>`                         | 最後に Events が出る → 問題発見の近道                                                 |
|                           | `kubectl top pod`                                | `metrics-server` が無いと動かない。試験環境では有効                                       |
| **マルチコンテナ Pod**           | sharedVolume (emptyDir)                          | サイドカーとメインで RW 共有。                                                        |
|                           | lifecycle/termination                            | Sidecar がないと Pod Completed で Job 失敗など                                    |

---

### 使い方メモ

- **カテゴリ単位**で YAML をコピペ → `kubectl apply` → 状態確認 → 削除、を 15 分スプリントで回すと CKAD 速度がつきます。
    
- 不安な項目は `kubectl explain <Resource>.<field>` で即参照。本番環境でも TAB 補完が効きます。
    
- **試験時間 (2h)** はコマンド短縮が鍵。`apo=kubectl apply -f` など alias を事前に仕込めるかチェックしましょう。