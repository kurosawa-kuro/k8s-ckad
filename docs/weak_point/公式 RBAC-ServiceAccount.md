## 🚀 CKAD RBAC ― “これだけ” スタートアップメモ

(**YAML は公式 × 最小パターンをそのまま掲載／行内コメントも温存**)

---

### 0️⃣ なぜ **ServiceAccount → RoleBinding → Role** の３枚だけ？

1. **Kubernetes が権限チェックするときの順番**
    
    1. _誰？_ → **ServiceAccount (SA)**
        
    2. _その SA は何の Role に紐付いている？_ → **(Cluster)RoleBinding**
        
    3. _Role の中で何が許可されている？_ → **(Cluster)Role**
        
2. **デバッグもこの“上流→下流”順に見れば 即ハマり箇所が分かる**
    
    > 認証エラー → Binding の typo → Role の verbs… と階段を下りるイメージ。
    

---

## 1️⃣ ServiceAccount — _まず「誰？」を名乗る_

```yaml
apiVersion: v1
kind: ServiceAccount       # ① 認証トークンを持つ身分証
metadata:
  name: demo-sa            #   Pod から指定する名前
  namespace: default       #   ← SA は名前空間リソース
```

_Pod では_ `spec.serviceAccountName: demo-sa` **を 1 行書くだけ**  
→ その Pod の API リクエストは demo-sa の権限で判定される。

---

## 2️⃣ RoleBinding — _「誰にどの Role？」を橋渡し_

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding               # ② “身分証” と “役割” を橋渡し
metadata:
  name: read-pods-binding
  namespace: default            #   ← Binding も名前空間リソース
subjects:                       #   ↓「誰」に権限を渡すか
- kind: ServiceAccount
  name: demo-sa                 #   ← ① の SA
  namespace: default
roleRef:                        #   ↓ どの Role（or ClusterRole）？
  kind: Role
  name: pod-reader              #   ← ③ の Role 名
  apiGroup: rbac.authorization.k8s.io
```

> **✓ チェックポイント** Subject と RoleRef の **namespace 書き忘れ**が鉄板ミス。

---

## 3️⃣ Role — _「何を許す？」を定義_

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role                        # ③ 名前空間内だけ有効な権限セット
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]                 # "" = Core API（Pod 等）
  resources: ["pods"]             # 対象リソース
  verbs: ["get", "list", "watch"] # 許可アクション
```

_クラスタ全体用_ にしたいときは `Role → ClusterRole` / `RoleBinding → ClusterRoleBinding` へ置換するだけ。

---

### 🔄「Role が後で出来ても OK？」

はい。RoleBinding は _名前を文字列参照_ しているだけなので、  
**先に Binding を apply → あとから Role を apply** しても自動で繋がります。

---

## 4️⃣ “30 秒セルフチェック” コマンド

```bash
# SA を使っているか確認
kubectl get pod mypod -o jsonpath='{.spec.serviceAccountName}'

# その SA に操作権があるか即判定
kubectl auth can-i list pods \
  --as system:serviceaccount:default:demo-sa
```

`no` なら **Binding → Role → namespace** の順に落とし込み調査。

---

## 5️⃣ Cluster 全体に効かせたいとき

```yaml
# --- ClusterRole ---
kind: ClusterRole
metadata:
  name: nodes-reader
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get","list"]

# --- ClusterRoleBinding ---
kind: ClusterRoleBinding
metadata:
  name: read-nodes-binding
subjects:
- kind: ServiceAccount
  name: demo-sa
  namespace: default
roleRef:
  kind: ClusterRole
  name: nodes-reader
  apiGroup: rbac.authorization.k8s.io
```

---

## 6️⃣ “よくある CKAD ミス” → 確認表

|チェック段|見る場所|典型的な落とし穴|１発コマンド例|
|---|---|---|---|
|① SA 参照|Pod `spec.serviceAccountName`|名前タイポ／default SA のまま|`kubectl get pod my -o 'jsonpath={.spec.serviceAccountName}'`|
|② SA オブジェクト|`kubectl get sa demo-sa -n default`|Namespace 違いで見つからない|–|
|③ Binding|subjects.kind/name/namespace|User になってる・NS 違い|`kubectl get rolebinding rb -o yaml`|
|④ roleRef|kind/name Typo|Role↔ClusterRole 取り違え|`kubectl describe rolebinding rb`|
|⑤ Role ルール|apiGroups / resources / verbs|"" と "apps" を混同|`kubectl auth can-i create deploy --as ...`|

---

## 7️⃣ これで書ける／直せること

|やりたい事|触る YAML|変える行|
|---|---|---|
|Pod に専用資格を付ける|**① SA**|`metadata.name`|
|NS 内で Pod を読ませる|**③ Role**|`resources`, `verbs`|
|その権限を SA に付与|**② RoleBinding**|`subjects.name`, `roleRef.name`|
|クラスタ全体を読ませる|**ClusterRole + ClusterRoleBinding**|`kind` を Cluster… に|

---

### 💡 暗記のコツ

- **Binding から疑う** — “橋” が掛かっていないだけの事故が最多
    
- **API グループ** — Core は `""`、Deploy なら `"apps"`
    
- **Namespace 三点セット** — _Pod / ServiceAccount / RoleBinding(subject)_
    

これだけで **RBAC 系は 5 分以内に原因特定 → 修正** できます。