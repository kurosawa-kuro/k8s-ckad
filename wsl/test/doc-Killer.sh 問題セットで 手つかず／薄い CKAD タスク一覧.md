killer.shレベルの問題を作成依頼、問題を作成する際に必要なリソースYAMLも提供依頼。この時点で解答は不要。

### Killer.sh 問題セットで **手つかず／薄い** CKAD タスク一覧

（CKAD v1.32 公式カリキュラム対比）([CNCF][1])

| カテゴリ                                        | 未出または不足している代表タスク                                                                                                                                                                         | コメント                                                            |
| ------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| **Application Design & Build**              | \* CronJob の作成・運用<br>\* StatefulSet／DaemonSet の設計<br>\* Multi-container Pod パターンの “Ambassador / Adapter” 例<br>\* PodDisruptionBudget                                                     | Job と Sidecar は出るが、上記はゼロまたは言及のみ                                 |
| **Application Deployment**                  | \* Horizontal Pod Autoscaler（HPA）<br>\* Deployment の *canary／blue-green* など分割ロールアウト                                                                                                      | ロールバック（`kubectl rollout undo`）は Q8 で触れているが HPA は未登場             |
| **Application Env, Config & Security**      | \* RBAC（Role／RoleBinding）設定と SA への権限付与<br>\* ResourceQuota／LimitRange の作成<br>\* Downward API（`fieldRef`/`resourceFieldRef`）<br>\* ImagePullSecret（`docker-registry` 型 Secret と SA への紐付け） | Secret／ConfigMap マウントは扱うが、上記はカバー外                               |
| **Application Observability & Maintenance** | \* LivenessProbe／StartupProbe（Readiness のみ）<br>\* Ephemeral Container 利用の `kubectl debug`<br>\* `kubectl port-forward`／`cp` など Pod デバッグ補助                                                | ログ収集サイドカーは Q16 で扱うが probe・debug 系は不足                            |
| **Services & Networking**                   | \* Ingress／IngressClass と TLS 設定<br>\* Headless Service & Stateful DNS<br>\* ExternalName Service<br>\* NetworkPolicy の DNS・Egress 以外の詳細（IP ブロック、namespaceSelector など）                   | ClusterIP／NodePort／NetworkPolicy 基礎は出題済み                        |
| **スケジューリング補助**                              | \* Affinity / Anti-Affinity<br>\* NodeSelector／nodeName<br>\* Taints & Tolerations<br>\* PriorityClass                                                                                   | スケジューラ関連はほぼ未出                                                   |
| **ストレージ**                                   | \* 動的プロビジョニング（StorageClass 指定の PVC だけで完結）<br>\* Volume Expansion (`pvc.spec.resources.requests`)                                                                                         | Q12/Q13 は *静的* hostPath + SC 作成で、本来 CKAD が狙う *PVC 主体* シナリオがやや薄め |

> **補足**
> *Helm*（Q4）や *StorageClass 作成*（Q13）は **CKAD 公式シラバス外** なので、逆に本番対策では優先度を下げても OK です。

---

#### 使い方のヒント

* このリストのタスクで 1 問ずつ “雛形 → 最小 YAML → `kubectl apply`” を練習すると **残り 10 % 程度の死角** を埋められます。
* 公式ドキュメント内リンク集を `~/.ckad-cheatsheet` に追記しておくと、本番での検索時間 (Ctrl+F) を短縮できます。

これで Killer.sh 問題集の穴を意識した学習スコープが整理できるはず。
追加ドリルを作りたい項目があれば気軽にリクエストしてください！

[1]: https://www.cncf.io/certification/cka-cirriculum "GitHub - cncf/curriculum: Open Source Curriculum for CNCF Certification Courses"
