### CKAD で出題される “カナリア-デプロイ” タスクの実態と対策

|よく出る作業|典型的な設問例|ひっかけポイント|
|---|---|---|
|**既存 Deployment を複製して canary 用を作る**|`current-krill-deployment` をコピーし、同じ namespace に `canary-krill-deployment` を作成せよ ([pass4success.com](https://www.pass4success.com/linux-foundation/discussions/exam-ckad-topic-2-question-53-discussion "Discuss Linux Foundation CKAD Exam Topic 2 Question 53 \| Pass4Success"))|`metadata.name` だけでなく `labels` / `selector` を丸ごと複製しないと Service が片方しか拾わない|
|**レプリカ数を % で調整**|「合計 Pod 数 ≤ 10、うち 40 % を canary に」→ 6 pod + 4 pod の計算を自分で行う ([GitHub](https://github.com/dgkanatsios/CKAD-exercises/issues/244 "[Help] Canary Deployment question · Issue #244 · dgkanatsios/CKAD-exercises · GitHub"))|Service は Pod 数の比率でしか分散しない＝**小数点切り捨て** に注意|
|**Service セレクターを両方に一致させる**|ラベル違いで Service が片側しか見えず通信できないケース|コピー時に `app=…` ラベルを変えてしまい Service から外れる|
|**Deployment 内で RollingUpdate パラメータをいじる**（稀）|`maxSurge: 2` / `maxUnavailable: 0` を設定し、段階的に 20 % だけ新バージョンを投入|フィールドは **spec.strategy.rollingUpdate.*** の配下；`%` と絶対値の混在ミス|

---

#### 出題頻度 & 配点イメージ

- カリキュラム Domain **「Application Deployment 20 %」** で “青/緑 またはカナリアなど” が明記 ([Linux Foundation - Education](https://training.linuxfoundation.org/ja/certification/certified-kubernetes-application-developer-ckad/ "認定 Kubernetes アプリケーション開発者 (CKAD) - Linux Foundation - 教育"))
    
- 本番では **ほぼ毎回 1 問（4〜7 %）**。Docker 問題と同じく “落とせないけど短時間で終わる” ポジション。
    

---

#### 実際に出る 2 大パターン

|パターン|中身|クリア手順(高速版)|
|---|---|---|
|**① 二重 Deployment 型（最頻出）**|_krill_ 問題のように、 _既存 Deployment_ と _canary Deployment_ で Pod 数比を作る ([Slides](https://slides.com/deepakdubey123/ckad-canary-deployment "CKAD - Canary Deployment"))|```bash|

# コピーして編集

k -n ns get deploy current -o yaml > canary.yaml  
sed -i 's/name: current/name: canary/' canary.yaml  
k apply -f canary.yaml

# 比率計算: 40% of 10 = 4

k -n ns scale deploy current --replicas=6  
k -n ns scale deploy canary --replicas=4

````|
| **② 単一 Deployment RollingUpdate 型** | 1 つの Deployment を更新し、`maxSurge/maxUnavailable` で段階投入 | ```bash
k set image deploy app app=repo:v2
kubectl -n ns patch deploy app -p '{
 "spec":{"strategy":{"type":"RollingUpdate",
  "rollingUpdate":{"maxSurge":"20%","maxUnavailable":0}}}}'
k rollout status deploy app
``` |

> **ポイント**  
> * Service レベルで「40 % split」等の高度なトラフィック制御は **出題されない**。Pod 数比率で近似すれば合格点。  
> * `kubectl get deploy -o yaml > file.yaml` → `vi` で複製 → `kubectl apply -f` が最速。  
> * 作業は **5 分以内** を目標に練習しておくと、難問に時間を回せる。

---

#### チートシート（暗記推奨コマンド）

```bash
# 複製用テンプレ取得
k -n <ns> get deploy <name> -o yaml > clone.yaml

# 名前・ラベル書き換え → 適用
k apply -f clone.yaml

# レプリカ即変更
k -n <ns> scale deploy <d> --replicas=<n>

# RollingUpdate パラメータだけ後付け
k -n <ns> patch deploy <d> \
  -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge":"1","maxUnavailable":0}}}}'

# 進行監視
k rollout status deploy <d>
````

---

#### まとめ

- **問題文を読んだらまず計算（合計 Pod 上限 × 割合）**。
    
- **コピー → scale** の 2 手が定番。Service いじるのは例外的。
    
- 公式ドキュメントに頼らず書けるよう、`clone + patch + scale` 手順を体で覚えておくと CKAD 本番で時短できます。