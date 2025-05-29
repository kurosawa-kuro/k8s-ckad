### 結論だけ — 「node/pod Affinity 系は CKAD では **ほぼ出ない**。出ても“おまけ”で 1〜2 % 程度」

|根拠|ソース|
|---|---|
|**公式カリキュラム v1.32** では Pod Design (20 %) の学習項目に _nodeSelector / Affinity_ の記載がそもそも無い (= 重みゼロ)|([Scribd](https://www.scribd.com/document/506933581/CKAD-Curriculum-V1-20?utm_source=chatgpt.com "Certified Kubernetes Application Developer (CKAD) Exam Curriculum"))|
|直近合格者の総まとめ記事でも **“CKAD なら Node Selector / Affinity / Taints はスキップで可”** と明言|([Medium](https://medium.com/%40codebob75/passing-ckad-cheatsheet-notes-and-tips-1aa285e6a473 "How to pass CKAD \| Medium"))|
|実受験者レポート（killer.sh 模試を含む）における出題率は **0 ～ 1 問／全 16–19 問**（≒0～7 %）で、しかも「Pod に既に書かれている Affinity を読み替える程度」と報告が多い|([Medium](https://medium.com/%40codebob75/passing-ckad-cheatsheet-notes-and-tips-1aa285e6a473?utm_source=chatgpt.com "Passing CKAD: cheatsheet, notes and tips - Medium"), [devopscube.com](https://devopscube.com/ckad-exam-study-guide/?utm_source=chatgpt.com "CKAD Certification: The Comprehensive Guide for Future CKADs"))|

---

## どのくらい備えておけば十分か？

|学習深度|目安|試験で困らないライン|
|---|---|---|
|**覚える YAML 行数**|・`requiredDuringScheduling…` を 1 ブロック書ける程度・`preferred… weight` が何か分かる|**5 行×1 回** 手書きしておく|
|**kubectl コマンド**|実戦ではほぼ不要（編集なら `kubectl edit` で十分）|—|
|**時間配分**|全勉強時間の **1〜2 h** で OK|深追いは非効率|

---

## “もし” 出た場合の典型パターン

|出題タイプ|難易度|解き方|
|---|---|---|
|**① 既存 Pod 定義に 1 行追加**「GPU ノードに必ず置きたい」|★☆☆|`nodeAffinity.required… matchExpressions` を 1 つ足す|
|**② Anti-Affinity で同一ノード禁止**（3 Replicas をホスト分散）|★★☆|`podAntiAffinity.required… topologyKey: kubernetes.io/hostname`|
|**③ preferred だけで“出来れば”配置**|★☆☆|`weight: 100` をテンプレにコピペ|

→ いずれも **コピペ＋ラベル合わせで 2～3 分**。  
深いアルゴリズム計算や JSONPatch は出ません。

---

## まとめ

- **配点・頻度ともに低く、CKAD 合格に必須ではない**  
    _重点は Docker/Canary/Probe/SecurityContext／NetworkPolicy など高配点トピックに。_
    
- とはいえ “見た瞬間に怖くない” よう、**required と preferred の違い＋最小 YAML** だけは練習しておくと安心。
    
- **時間が足りない初心者は「後回し or 最後の 1 h」でも全く問題ない**領域です。