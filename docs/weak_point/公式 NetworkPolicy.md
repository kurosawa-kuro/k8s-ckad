# Kubernetes NetworkPolicy — CKAD 速習ノート

> **狙い**：公式サンプルをそのまま動かしながら **許可 → 制限 → 例外** の流れでネットワーク制御を短時間で体得し、CKAD 試験に備える。

---

## 0. 学習ロードマップ

|Step|触るリソース|習得ポイント|
|---|---|---|
|1|**ポリシー無し** (デフォルト許可)|クラスタ初期状態を確認|
|2|**全拒否ポリシー (Default Deny)**|`podSelector:{}` & `policyTypes` の意味|
|3|**Ingress 許可**|ラベルで通信元を限定|
|4|**Egress 許可**|CIDR / IPBlock の扱い|
|5|**Namespace 間通信**|`namespaceSelector` の使い方|
|6|**DNS egress**|CoreDNS ↔ 外部通信の扱い|

---

## 1️⃣ 前提：動作確認用 Deployment & Service

> **ポイント**：以降は **Deployment に統一**。`kubectl run` は Pod を直接生成するため、`kubectl exec deploy/...` が失敗する。
> 
> また `kubectl create deployment` は Pod テンプレートに自動で `app=<deployment名>` ラベルを付与するので、追加の `--labels` オプションは不要です（古いバージョンではそもそも未実装）。

```bash
# 名前空間
kubectl create ns demo

# frontend
kubectl create deployment frontend --image=nginx -n demo
kubectl expose  deployment frontend --port 80 --target-port 80 -n demo

# backend
kubectl create deployment backend  --image=nginx -n demo
kubectl expose  deployment backend  --port 80 --target-port 80 -n demo
```

疎通確認:

```bash
kubectl exec -n demo deploy/frontend -- curl -s backend.demo.svc.cluster.local
```

---

## 2️⃣ Default Deny — **全拒否ポリシー**

> **重要 — CNI プラグインの対応を確認せよ**  
> NetworkPolicy は **CNI プラグイン側で実装されていないと無効** になります。
> 
> - Flannel / kindnet など _非対応_ のままでは、`default-deny-all` を適用しても通信は遮断されません。
>     
> - Calico・Cilium・Antrea など _対応_ プラグインを導入するとポリシーが正しく効きます。
>     
>     - kind で Calico を使う例: `kind create cluster --config kind-calico.yaml`
>         

- **minikube** で NetworkPolicy を有効にするには **バージョン** と **CNI ドライバ** がカギです。
    

### 1) まずバージョン & 利用可能アドオンを確認

```bash
minikube version          # v1.32.0 以上推奨
minikube addons list | grep -E "calico|cilium|antrea"
```

- **一覧に何も出ない場合は古い minikube** です。公式バイナリを更新するのが最速。
    
    ```bash
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    ```
    

### 2) 新規クラスタで CNI を指定 (最も確実)

```bash
minikube delete                       # 既存クラスタを消しても良ければ
minikube start --cni=calico           # または --cni=antrea / --cni=cilium
```

> `docker` ドライバの場合は追加オプション不要。`--driver=none` など裸環境では権限に注意。

### 3) 既存クラスタに CNI アドオンを後付けする (_addon がある場合のみ_)

> **時短 TIP**: `minikube start --cni=<name>` でクラスタを作ったら **すでに CNI がデプロイ済み** です。追加の `minikube addons enable <name>` は不要なので _スキップ_ してください。実行すると次のエラーが出ても問題ありません。
> 
> ```text
> <name> is not a valid addon
> ```
> 
> - もし `--cni` を付けずにクラスタを作成した場合のみ、下記コマンドで後付けできます。
>     
> 
> ```bash
> minikube addons enable calico     # または antrea / cilium (addons list にあるもの)
> ```

### 4) CNI Pod が起動したか確認 CNI Pod が起動したか確認

```bash
# ノード DaemonSet (calico-node) が Running か
kubectl get pods -n kube-system -l k8s-app=calico-node

# コントローラ (calico-kube-controllers) も Ready か
kubectl get pods -n kube-system -l k8s-app=calico-kube-controllers
```

両方とも `Running` になったのを確認してから `default-deny-all.yaml` を再テスト。

確認コマンド例: `kubectl get pods -n kube-system -l k8s-app=calico-node` で Calico Pod の有無をチェック。  
Default Deny — **全拒否ポリシー**

`default-deny-all.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: demo
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

```bash
kubectl apply -f default-deny-all.yaml
# 既存 Deployment / Service / Pod の再作成は **不要**
# → ポリシーは即時に適用される。
```

> - `podSelector:{}` = 名前空間内の全 Pod
>     
> - `policyTypes` を省略すると ingress/egress のうち yaml に書いた方向のみ適用
>     
> - **NetworkPolicy はデータプレーンで動的に評価されるため、既存リソースの再デプロイは不要**。
>     

---

### ▶︎ default‑deny を一時的に解除したい場合

開発やデバッグで「ポリシー前の状態に戻して通信確認したい」ときは、対象名前空間の **すべての NetworkPolicy を削除** すれば **即時で全許可** に戻ります。

```bash
# demo 名前空間の NetworkPolicy 一覧を確認
kubectl get netpol -n demo

# default‑deny が残っていると “何も通らない” のでまず確認！
# (allow-... だけ消すと引き続き遮断される)

# 個別に削除する場合
kubectl delete netpol default-deny-all -n demo

# まとめて削除する場合 (default-deny も含め全て)
kubectl delete netpol --all -n demo
```

> **ハマりやすい!** `allow-*` だけ削除して「まだ通らない…」となったら、`default-deny-all` が残っていないか必ずチェックする。
> 
> Pod / Service は再作成不要。ポリシーを apply / delete するだけで挙動が切り替わることを覚えておくと CKAD でスピードアップできます。ポリシーを apply / delete するだけで挙動が切り替わることを覚えておくと CKAD でスピードアップできます。
> 
> - ただしポリシーが **ラベルに依存** していて、あとから Pod ラベルを変更した場合は `kubectl label` で動的に反映される（一度 Pod を消す必要はない）。
>     

---

## 3️⃣ Ingress 許可 — **frontend → backend**

> **ハマりポイント**：このポリシーは _Ingress だけ_ を許可します。既に `default-deny-all` で **Egress** も遮断している場合、`frontend` Pod は **CoreDNS へ名前解決できず** `curl` が _exit code 6_ になります。
> 
> - 試験でも頻出：**DNS egress を別ポリシーで許可**するか、下記 YAML をワンショットで追記すれば解決します。
>     
> 
> ```yaml
> apiVersion: networking.k8s.io/v1
> kind: NetworkPolicy
> metadata:
>   name: allow-frontend-with-dns
>   namespace: demo
> spec:
>   podSelector:
>     matchLabels:
>       app: frontend
>   egress:
>   - to:
>     - namespaceSelector: {}
>       podSelector:
>         matchLabels:
>           k8s-app: kube-dns   # CoreDNS Pod (kube-system)
>     ports:
>     - protocol: UDP
>       port: 53
>     - protocol: TCP
>       port: 53
>   policyTypes:
>   - Egress
>   # --- 既存の ingress ルール (backend への許可) ----
>   ingress:
>   - from:
>     - podSelector:
>         matchLabels:
>           app: frontend
>     ports:
>     - protocol: TCP
>       port: 80
>   policyTypes:
>   - Ingress
> ```
> 
> もちろん、**ステップ 6 (DNS egress)** を先に適用しても OK です。

`allow-frontend.yaml` (Ingress **のみ**):

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend
  namespace: demo
spec:
  podSelector:
    matchLabels:
      app: backend      # 対象 Pod
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend # 許可元
    ports:
    - protocol: TCP
      port: 80
  policyTypes:
  - Ingress
```

---

### 3.1 **frontend → backend の Egress を許可**

`allow-frontend-egress.yaml` (変更なし)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-egress
  namespace: demo
spec:
  podSelector:
    matchLabels:
      app: frontend
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 80
  policyTypes:
  - Egress
```

### 3.2 **DNS への Egress を許可 (必須)**

`frontend` Pod がクラスタ DNS (CoreDNS) へ到達できないと名前解決に失敗し、`curl` が _exit code 6_／_28_ になります。必須ポリシーは下記いずれか 1 つ。

#### パターン A: Pod ラベルで許可 (推奨)

`allow-dns-egress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: demo
spec:
  podSelector:
    matchLabels:
      app: frontend
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
  policyTypes:
  - Egress
```

#### パターン B: ClusterIP で許可 (簡易)

1. DNS サービス IP を取得:
    
    ```bash
    DNS_IP=$(kubectl get svc kube-dns -n kube-system -o jsonpath='{.spec.clusterIP}')
    ```
    
2. `allow-dns-egress-ip.yaml`:
    
    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: allow-dns-egress-ip
      namespace: demo
    spec:
      podSelector:
        matchLabels:
          app: frontend
      egress:
      - to:
        - ipBlock:
            cidr: ${DNS_IP}/32  # 例: 10.96.0.10/32
        ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
      policyTypes:
      - Egress
    ```
    

> CKAD 試験では **ラベル方式 (パターン A)** がタイピング量少なくおすすめ。

適用順の例:

```bash
kubectl apply -f allow-frontend.yaml          # Ingress backend->frontend
kubectl apply -f allow-frontend-egress.yaml   # Egress frontend->backend
kubectl apply -f allow-dns-egress.yaml        # Egress frontend->CoreDNS

# ==> HTML が返るはず
kubectl exec -n demo deploy/frontend -- curl -s backend.demo.svc.cluster.local
```

テスト:

```bash
kubectl apply -f allow-frontend.yaml          # Ingress
kubectl apply -f allow-frontend-egress.yaml   # Egress

# DNS egress も必要なら (exit code 6 が出る場合)
kubectl apply -f allow-dns-egress.yaml        # ← 先ほど例示した YAML

# 期待動作: HTML が返る
kubectl exec -n demo deploy/frontend -- \
  curl -s backend.demo.svc.cluster.local
```

kubectl apply -f allow-frontend.yaml  
kubectl exec -n demo deploy/frontend --  
curl -m2 -s backend.demo.svc.cluster.local # exit code 6 なら DNS egress を追加

```
kubectl apply -f allow-frontend.yaml
kubectl exec -n demo deploy/frontend -- \
  curl -s backend.demo.svc.cluster.local  # ✅
```

---

## 4️⃣ Egress 許可 — **外部 HTTPS のみ**

`egress-to-external.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-external
  namespace: demo
spec:
  podSelector:
    matchLabels:
      app: frontend
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 10.0.0.0/8     # 社内 NW を除外
    ports:
    - protocol: TCP
      port: 443
  policyTypes:
  - Egress
```

テスト:

```bash
kubectl exec -n demo deploy/frontend -- \
  sh -c 'curl -m2 https://example.com && curl -m2 http://example.com || true'
```

---

## 5️⃣ Namespace セレクター — **monitoring ns のみ許可**

`allow-from-monitoring-ns.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-monitoring
  namespace: demo
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          purpose: monitoring
    ports:
    - protocol: TCP
      port: 80
  policyTypes:
  - Ingress
```

```bash
kubectl create ns monitoring
kubectl label ns monitoring purpose=monitoring
```

---

## 6️⃣ 運用 Tips

|目的|コマンド|
|---|---|
|ポリシー一覧|`kubectl get netpol -A`|
|詳細確認|`kubectl describe netpol <name> -n <ns>`|
|雛形作成|`kubectl create netpol deny --dry-run=client -o yaml > np.yaml`|
|Pod 取得→ exec|`kubectl exec -n demo $(kubectl get pod -n demo -l app=frontend -o jsonpath='{.items[0].metadata.name}') -- sh`|
|BusyBox テスト|`kubectl run test -it --rm --image=busybox:1.35 -- sh`|

---

### まとめ

- **Deployment に統一**しておけば `kubectl exec deploy/<name>` がそのまま使えて楽。
    
- ネットワークポリシーは **Default Deny → 必要最小限許可** が鉄則。
    
- CKAD で問われる YAML はほぼ `podSelector`, `policyTypes`, `ingress/egress` の組み合わせ。雛形を暗記しタイピング最小化で高得点！
    

質問や追加例のリクエストがあればいつでもどうぞ！