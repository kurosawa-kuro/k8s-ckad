# Killer.sh ローカル再現 & 実戦チートシート

> **目的**
> *Killer.sh*／CKAD 本番の各シナリオを **自宅 minikube/Kind 環境**で高速に再現し、同じ手順で解答を検証するための “手順書 & 暗記テンプレ” です。

---

## 1️⃣ クラスタ初期化

```bash
cd ~/dev/k8s-ckad/wsl/script
make reset-heavy      # ─ 全リソースを一掃してクリーン開始
```

> *minikube を Calico 付きで起動する場合は*
> `minikube delete && minikube start --network-plugin=cni --cni=calico`

---

## 2️⃣ kubectl エイリアス & お役立ち関数

```bash
alias k=kubectl
alias kn='kubectl config set-context --current --namespace '
alias kcfg='kubectl get cm,secret,sa,role,pvc,svc,events -n'
export do='--dry-run=client -o yaml'   # ▶️ 生成 → ペースト用
```

### よく使うヘルプ・スニペット

```bash
kubectl config set-context --current --help | grep -A3 -B3 -- --namespace
kubectl explain pod.spec.containers.securityContext.allowPrivilegeEscalation
```

---

## 3️⃣ “即席リソース” 生成ワンライナー

| 用途                                                                            | コマンド                                                                                                                                  |
| ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Job** スケルトン                                                                 | `kubectl create job my-job --image=busybox:1.31.0 -n neptune $do -- /bin/sh -c "sleep 2 && echo done" > job.yaml`                     |
| **readinessProbe Pod**                                                        | `kubectl run pod6 --image=busybox:1.31.0 --restart=Never $do --command -- /bin/sh -c 'touch /tmp/ready && sleep 1d' > pod6-skel.yaml` |
| **ClusterIP テスト**                                                             | \`\`\`bash                                                                                                                            |
| kubectl run nginx --image=nginx:1.17.3-alpine --restart=Never \\              |                                                                                                                                       |
| --labels=project=plt-6cc-api --port=80 -n pluto                               |                                                                                                                                       |
| kubectl expose pod nginx --name=plt-svc --port=3333 --target-port=80 -n pluto |                                                                                                                                       |

````|
| **curl from container** | `kubectl run curl -n pluto --rm -it --restart=Never --image=curlimages/curl -- curl -s plt-svc:3333` |

---
## 4️⃣ ストレージ & トークン確認
```bash
# ServiceAccount トークンデコード
kubectl get secret neptune-sa-v2-token -n neptune -o jsonpath={.data.token} | base64 -d

# Secret2 の中身を見る
kubectl get secret secret2 -n moon -o jsonpath={.data.config} | base64 -d
````

---

## 5️⃣ ポート対応チート表

| フェーズ   | YAML フィールド                                    | 役割                        |
| ------ | --------------------------------------------- | ------------------------- |
| **入口** | `Service.spec.ports[].port`                   | クライアントが叩く Service ポート     |
| **出口** | `Service.spec.ports[].targetPort`             | kube-proxy が Pod へ転送するポート |
| **着地** | `Pod.spec.containers[].ports[].containerPort` | アプリが LISTEN する実ポート        |

---

## 6️⃣ Secret / ConfigMap 速攻テンプレ

### 6‑1 環境変数に 1 キーだけ

```yaml
env:
  - name: DB_PASS
    valueFrom:
      secretKeyRef:
        name: db-secret
        key: password
```

### 6‑2 Secret 丸ごと ENV

```yaml
envFrom:
  - secretRef:
      name: db-secret
      prefix: DB_
```

### 6‑3 Secret をボリュームマウント

```yaml
volumes:
  - name: db-secret-vol
    secret:
      secretName: db-secret
      # defaultMode: 0440  # 任意
---
volumeMounts:
  - name: db-secret-vol
    mountPath: /etc/secret
    readOnly: true
```

---

## 7️⃣ ロギング・サイドカーの確認

```bash
# cleaner デプロイの稼働中 Pod 名取得
NEW_POD=$(kubectl get pod -l app=cleaner -n mercury -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}')
# ロガーサイドカーのログ
kubectl logs -f "$NEW_POD" -c logger-con -n mercury
```

---

## 8️⃣ ラベル & アノテーション一括操作

```bash
# worker / runner → protected=true
kubectl label pod -n sun -l 'type in (worker,runner)' protected=true --overwrite
# protected=true へアノテーション
kubectl annotate pod -n sun -l protected=true \
  protected='do not delete this pod' --overwrite
```

---

## 9️⃣ NetworkPolicy セレクタ早見

```bash
# Set ベース: 値が worker か runner
-l 'type in (worker,runner)'

# キーが存在しない
-l '!version'
```

---

## 10️⃣ 疑似テスト用 YAML 雛形リンク

* Q12 PV/PVC/Deployment  … `q12-setup.yaml`
* Q18 ClusterIP→Fix      … `q18-setup.yaml`
* Q19 NodePort テスト     … `q19-setup.yaml`
  *👉 上記は各シナリオを再現する最小 YAML。編集しながら学習ループを回す*

---

### ✨ ワークフロー早見

1. `make reset-heavy` でクリーン開始
2. `kubectl apply -f qXX-setup.yaml` で課題初期状態再現
3. エディタで修正 → `kubectl apply -f`  → エイリアスコマンドで確認
4. ⏱️ **タイマーをセットして模試** → ミスをメモ → ドキュメント更新

> 🐾 迷ったらこのシートに戻ってコマンドをコピペ → 試験本番へ！
