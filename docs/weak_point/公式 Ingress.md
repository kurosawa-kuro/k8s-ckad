### CKAD で “とりあえず書ける” 公式 Ingress スニペットは **この 12 行** だけ覚えれば OK

> 出典：K8s ドキュメント `service/networking/minimal-ingress.yaml`（コメントだけ追記）

```yaml
apiVersion: networking.k8s.io/v1   # ← Ingress は必ずこの API
kind: Ingress                      # ← リソース種別
metadata:
  name: minimal-ingress            # ← Ingress 名（DNS サブドメイン）
  annotations:                     # ← NGINX系で書き換えを入れる時など
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx          # ← controller 名 (省略可: default があれば)
  rules:
  - http:                          # ← 今は HTTP/S ルールのみ
      paths:
      - path: /test                # ← マッチさせたい URI
        pathType: Prefix           # ← Exact / Prefix / ImplementationSpecific
        backend:                   # ← Ingress が実際に転送を行う「行き先」を宣言するルートキー
          service:                 # ← 転送先 Service
            name: test             #   Service 名
            port:
              number: 80           #   Service の port 番号
```

```
# ---------- Service：Ingress が中継する受け口 ----------
apiVersion: v1
kind: Service
metadata:
  name: test                        # ← Ingress backend.service.name と一致
spec:
  selector:                         # ← このラベルを持つ Pod 群を束ねる
    app: test
  ports:
  - protocol: TCP
    port: 80                        # ← Ingress backend.port.number と一致
    targetPort: 80                  # ← Pod の containerPort

---
# ---------- Pod：実際にリクエストを処理するアプリ ----------
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  labels:
    app: test                       # ← Service の selector と一致
spec:
  containers:
  - name: echo
    image: hashicorp/http-echo:1.2.3           # 軽量 HTTP 返答サーバ
    args: ["-text=hello from ingress /test"]   # 返すメッセージ
    ports:
    - containerPort: 80              # ← Service / targetPort と合わせる
```
#### なぜこれだけで十分？

|CKAD 出題パターン|対応行|備考|
|---|---|---|
|**「/foo は svcA に」**|`path`, `service.name`|ホスト無しファンアウトは rules 配列を増やすだけ|
|**既存 Ingress へ rule 追記**|そのまま `kubectl edit ingress …`|diff を見る採点なので **追加行だけ** 正しければ通る|
|**TLS 証明書を付ける**|`spec.tls:` ブロックを 3-4 行足すだけ|他は同型|

> **公式サンプルが多くて迷う時は**  
> まずこの “minimal-ingress” をベースに、■ `ingressClassName` を環境に合わせる■ `rules[]` を増やす (host/path)  
> …という 2 ステップだけで 90 % の設問を解けます。

---

#### もっと欲しい場合に覚える“足し算”パターン

| 追加したい機能          | 公式ファイル名 / 行数                                          | 覚え方                                |
| ---------------- | ----------------------------------------------------- | ---------------------------------- |
| **Host ベース振り分け** | `name-virtual-host-ingress.yaml`（+1 行で `host:` を書くだけ） | `rules[].host: foo.bar.com` を付けるだけ |
| **複数パスのファンアウト**  | `simple-fanout-example.yaml`（rules を array で並べるだけ）    | `paths:` を増やす                      |
| **TLS**          | `tls-example-ingress.yaml`（`spec.tls:` を 4 行）         | `secretName:` と `hosts:` をセット      |

---

### まとめ — 試験当日にやること

1. **`kubectl create ingress minimal --dry-run=client -o yaml`**  
    （生成されない環境もあるので自分でテンプレ貼り付けても OK）
    
2. `service.name` と `port.number`、`path` だけ書き替え
    
3. 追加ルールはコピペ増殖 → 保存 → `kubectl apply -f`
    

> Ingress 問題は **タイピング量より“構文ミスゼロ”** が勝負。  
> 上記 12 行テンプレを丸暗記しておけば、CKAD の Ingress で落とすことはまずありません。


### ① TLS Secret ―― “鍵と証明書を **K8s オブジェクト** にしておく箱”

```yaml
apiVersion: v1                  # ← Core API（Secret は必ず v1）
kind: Secret                    # ← リソース種別：Secret
metadata:
  name: testsecret-tls          # ← Ingress から参照する Secret 名
  namespace: default            # ← 参照側（Ingress）と同じ NS に置く
data:                           # ← **base64 でエンコード**したバイト列を入れる
  tls.crt: <base64-cert>        #    公開鍵付き証明書 (必ずキー名 tls.crt)
  tls.key: <base64-key>         #    秘密鍵 (必ずキー名 tls.key)
type: kubernetes.io/tls         # ← TLS 用の定型タイプ
```

> ⚠️ **作り方ショートカット**  
> `kubectl create secret tls testsecret-tls \ --cert=PATH/server.crt --key=PATH/server.key \ -o yaml --dry-run=client > tls-secret.yaml`

---

### ② Ingress ―― “`https://https-example.foo.com/*` を Service1 へ”

```yaml
apiVersion: networking.k8s.io/v1   # ← Ingress 用 API
kind: Ingress                      # ← リソース種別
metadata:
  name: tls-example-ingress        # ← Ingress 名
spec:
  tls:                             # ← TLS セクション（1 つのポート 443 固定）
  - hosts:                         #    SNI でマッチさせる FQDN リスト
      - https-example.foo.com      #    証明書の CN/SAN と一致させる
    secretName: testsecret-tls     #    ↑ で作った TLS Secret を指定
  rules:                           # ← HTTP/S ルール
  - host: https-example.foo.com    #    Host ヘッダが一致したら…
    http:
      paths:
      - path: /                    #    URI パスが “/” 以下なら
        pathType: Prefix           #    Prefix マッチ（サブパス全部含む）
        backend:                   #    転送先を指定
          service:
            name: service1         #    Service 名
            port:
              number: 80           #    Service の公開ポート
```

#### 動きのイメージ

1. **ブラウザ** → `https://https-example.foo.com/anything`
    
2. Ingress Controller
    
    - 443 で TLS ハンドシェイク
        
    - SNI が `https-example.foo.com` → `testsecret-tls` で終端
        
3. **平文 HTTP** を Service `service1:80` へプロキシ
    

---

### CKAD で求められる最低スキル

|作業|コマンド / 手順|
|---|---|
|証明書⇒Secret 生成|`kubectl create secret tls …`|
|Ingress に TLS 追加|`spec.tls[]` ブロックを 4 行貼るだけ|
|動作確認|`kubectl get ingress` で `ADDRESS` が付くのを待つ → `curl -k https://HOST/`|

> **覚えるのは “`tls:` 4 行＋Secret 名” のみ。**  
> そのほかは通常の Ingress ルールと同じです。