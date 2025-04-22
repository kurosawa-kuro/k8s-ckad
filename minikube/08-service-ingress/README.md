# 📘 Kubernetesチュートリアル: Pod + Service + Ingress（ECR版・CKAD対応）

このチュートリアルでは、AWS ECR 上の **Node.js API** イメージを Minikube 環境で Pod として起動し、Service で公開、Ingress で HTTP ルーティングするまでを CKAD 試験想定でハンズオンします。

---

## 📂 作業ディレクトリ構成（例）

```bash
~/dev/k8s-ckad/minikube/01.2-service/
├── pod-ecr.yaml         # Pod ひな形（kubectl run で生成）
├── service.yaml         # Service ひな形（kubectl expose で生成）
├── ingress.yaml         # Ingress 手動作成
└── busybox-test.yaml    # busybox 検証用（kubectl run で生成）
```

> 💡 **YAML は出来る限り `kubectl run / expose` などで生成 → 必要箇所だけ手編集** という CKAD 本番の時短スタイルを徹底します。

---

## ✅ Step 1 — Pod YAML を生成

```bash
kubectl run nodejs-api-pod \
  --image=986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5 \
  --port=8000 --restart=Never \
  --dry-run=client -o yaml > pod-ecr.yaml
```

**最小編集ポイント**
1. `metadata.labels` を `app: nodejs-api` に変更
2. コンテナ名を `nodejs-api-container` に変更
3. `containerPort: 8000` を追記
4. `imagePullSecrets` に `ecr-registry-secret` を追加

---

## ✅ Step 2 — Pod 作成（初回は create --save-config 推奨）

```bash
kubectl create -f pod-ecr.yaml --save-config   # 初回のみ
# 以降は kubectl apply -f pod-ecr.yaml で差分反映可能
```

> ⚠️ **ポイント** : `--save-config` を付けておくと `kubectl.kubernetes.io/last-applied-configuration` が付与され、次回 `kubectl apply` でエラーになりません。

---

## ✅ Step 3 — Service YAML を生成

```bash
kubectl expose pod nodejs-api-pod \
  --name=nodejs-api-service --port=8000 --target-port=8000 \
  --type=NodePort --dry-run=client -o yaml > service.yaml
```

*任意* で `nodePort: 30080` （30000‑32767 の範囲）を追記すると EC2 の SG で 30080 だけ開ければ済みます。

---

## ✅ Step 4 — Service 作成

```bash
kubectl apply -f service.yaml
```

---

## ✅ Step 5 — Ingress YAML を作成（手動）

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nodejs-api-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: nodejs-api-service
                port:
                  number: 8000
```

```bash
kubectl apply -f ingress.yaml
```

> **Ingress Controller 未導入の場合**
>
> ```bash
> minikube addons enable ingress   # 1回だけ実行
> ```

---

## ✅ Step 6 — busybox テスト **Deployment** あるいは **Pod** の作成

CKAD では *検証用の簡易 Pod* で足りる場合が多いですが、**Deployment で作っておくと再生成が楽** というメリットがあります。お好みでどちらかを選択してください。

### 🅰 Option A: Deployment で作成（おすすめ）

```bash
# YAML ひな形を生成
kubectl create deployment busybox-test \
  --image=busybox --dry-run=client -o yaml > busybox-test.yaml

# ── 修正ポイント ─────────────────────────
# spec.template.spec.containers[0].command を次に変更
#   command: ["sh", "-c", "while true; do sleep 3600; done"]
# replicas を 1 に固定（デフォルト 1 のままでも OK）
# ────────────────────────────────────────

# create --save-config で初回作成
kubectl create -f busybox-test.yaml --save-config
```

### 🅱 Option B: ただの Pod で作成（最速）

```bash
kubectl run busybox-test --image=busybox \
  --command -- sh -c "while true; do sleep 3600; done" \
  --restart=Never --dry-run=client -o yaml > busybox-test.yaml
kubectl apply -f busybox-test.yaml   # create --save-config でも可
```

> **⚠️ AlreadyExists エラーが出たら**
>
> 既に同名リソースが残っている状態で `kubectl create` を実行すると `... already exists` で失敗します。<br>
> - `kubectl delete deployment busybox-test` もしくは `kubectl delete pod busybox-test` で一度消す<br>
> - あるいは `kubectl apply -f busybox-test.yaml` で上書き

---

## 🔍 Step 7 — ClusterIP 経由で内部アクセス確認 7 — ClusterIP 経由で内部アクセス確認

```bash
kubectl get svc nodejs-api-service -o wide
kubectl exec -it busybox-test -- wget -qO- http://nodejs-api-service:8000/
```

---

## 🌐 Step 8 — NodePort で外部アクセス

```bash
# 例）nodePort が 30080 の場合
curl http://<EC2のPublicIP>:30080/
```

EC2 Security Group で **30080/TCP** を開放しておきます。

---

## 🌐 Step 9 — Ingress 経由でアクセス

```bash
MINIKUBE_IP=$(minikube ip)
curl http://$MINIKUBE_IP/api/
```

---

## ✅ まとめ

| 学習目標 | コマンド | ポイント |
|----------|----------|----------|
| Pod ひな形作成 | `kubectl run --dry-run -o yaml` | 最小編集のみ |
| Service ひな形 | `kubectl expose --dry-run` | NodePort 固定可 |
| Ingress | 手動 YAML | `/api` → Service(8000) |
| 内部疎通 | `busybox` Pod | ClusterIP 解決 |
| 外部疎通 | NodePort / Ingress | SG・ルール確認 |

これで **Service + Ingress** を用いた安定ルーティングの一連が CKAD 試験形式で再現できます。次は Deployment / HPA / ConfigMap など応用編へチャレンジしてみましょう！

