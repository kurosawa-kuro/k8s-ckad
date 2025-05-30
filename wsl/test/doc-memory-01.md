# CKAD Quick Reference – 全情報保持版

> **注意**: 本ドキュメントはユーザー提供情報を**一切削除せず**再構成しています。

---

## 目次

0. はじめに
1. 環境まわり（毎回打つ alias 等）
2. YAML 生成コマンド（Imperative → スケルトン）
3. 調査・デバッグ用ショートカット
4. 変更・ロールアウト操作
5. “出たらラッキー” 10 秒ワンライナー
6. “ドキッ” とするリソース対策テンプレ

   * 6‑1. Liveness / Readiness Probe
   * 6‑2. NodeAffinity / PodAffinity
   * 6‑3. Taints / Tolerations
   * 6‑4. NetworkPolicy (Ingress / Egress)
   * 6‑5. StorageClass & PVC
   * 6‑6. SecurityContext
   * 6‑7. ServiceAccount と (Cluster)RoleBinding
7. 本番で困ったら：`kubectl explain` & スケルトン戦略
8. ポートフォワード & 一時 curl Pod
9. “訓練すべきこと” チェックリスト
10. `kubectl explain` ワンライナー早見表

---

## 0. はじめに

CKAD は **2 時間・20 問前後**。タイムロス回避のため、以下のコマンドは“指が勝手に動く”レベルで暗記推奨です。

---

## 1. 環境まわり – まずは毎回打つもの

| 覚えるもの                                                         | 役割 / ワンポイント                                                       |
| ------------------------------------------------------------- | ----------------------------------------------------------------- |
| `alias k=kubectl`                                             | ほぼ全員が使う定番。                                                        |
| `kubectl config -h \| grep context`                           | context 関連オプション確認用。                                               |
| `alias kn='kubectl config set-context --current --namespace'` | 名前空間切替。`kn kube-system` のように使う。                                   |
| `alias kctx='kubectl config use-context'`                     | context 切替も地味に出る。<br>☑ *kcd (= kubectx)* を入れておくと GUI 替わりになる。      |
| `source <(kubectl completion bash)`                           | タブ補完を入れるとタイポが激減。（`~/.bashrc` に書けば永続）                              |
| `export do='--dry-run=client -o yaml'`                        | 生成系コマンドを短く：<br>`k create deploy nginx --image=nginx $do > d.yaml` |

---

## 2. YAML 生成系 – 得点源になる Imperative コマンド

> 出題の 4〜5 割は “○○を作り YAML を編集して完成させろ”

```bash
# Deployment・Pod
k create deployment nginx --image=nginx $do > nginx-deploy.yaml
k run busy --image=busybox --command -- sh -c 'sleep 3600' $do > busy.yaml

# Service (ClusterIP / NodePort / LoadBalancer)
k expose deployment nginx --port=80 --target-port=8080 $do > svc.yaml

# Job / CronJob
k create job pi --image=perl -- perl -Mbignum=bpi -wle 'print bpi(2000)' $do > pi-job.yaml
k create cronjob hello --image=busybox --schedule="*/5 * * * *" -- sh -c 'date; echo Hi' $do > cj.yaml

# ConfigMap / Secret
k create configmap app-cfg --from-literal=APP_MODE=prod $do > cm.yaml
k create secret generic db --from-literal=PWD=passw0rd $do > sec.yaml
```

**ポイント**

* `k run` は **Pod**、`k create deployment` は **Deployment**。
* `$do` (= `--dry-run=client -o yaml`) をエイリアス化し毎回付与→リダイレクト `>` → `vim` 編集が最速。

---

## 3. 調査・デバッグ系 – 基本フロー & 便利エイリアス

### 3‑A. 推奨デバッグフロー（深掘りの順番）

| ステップ                                 | 1 行コマンド例                                    | 目的 / 判断ポイント                                                                         |
| ------------------------------------ | ------------------------------------------- | ----------------------------------------------------------------------------------- |
| **① `get`**                          | `k get pods -o wide`                        | **生存/Restart 回数・ノード配置**を俯瞰。「どの Pod を深掘りするか」を決める起点。                                  |
| **② `describe`**                     | `k describe pod <name>`                     | **Spec + Conditions + *Events*** を一気に確認。PVC/PV バインド失敗・Probe エラーなど “原因らしきメッセージ” を拾う。 |
| **③ `logs`**                         | `k logs <pod> [-c <ctr>]`                   | アプリ/Init/Sidecar すべての **出力エラー** を確認。CrashLoopBackOff 時は `--previous` も。             |
| **④ `events`**                       | `k events --for pod/<name> --types=Warning` | 直近の **Warning 系イベント** をタイムラインで並べ、`describe` では出ない他リソース由来の問題も拾う。                     |
| **⑤ `exec` / シェル**                   | `k exec -it <pod> -- sh`                    | 内部ファイル確認・`curl localhost` など **動的調査**。                                              |
| **⑥ `port-forward` / 一時 `curl` Pod** | `k port-forward svc/api 8080:80`            | **クラスタ外から疎通テスト**、Policy で塞がれていないか確認。                                                |

> **覚え方：Get → Describe → Logs → Events → Exec → External Test**

### 3‑B. 手打ち短縮エイリアス

```bash
kgp()  { k get pods -o wide "$@"; }       # Pod 一覧 (Step ①)
kd()   { k describe "$@"; }                # describe (Step ②)
kll()  { k logs -f "$@"; }                 # logs -f (Step ③)
kev()  { k events --for "$@" --types=Warning; }  # events (Step ④)
kex()  { k exec -it "$@" -- sh; }          # exec シェル (Step ⑤)
kpf()  { k port-forward "$@" 8080:80; }    # port‑forward (Step ⑥)
```

---

## 4. 変更・ロールアウト系 – 片手で打てる形に

変更・ロールアウト系 – 片手で打てる形に

| 操作           | 典型コマンド                                      | よく問われるポイント          |
| ------------ | ------------------------------------------- | ------------------- |
| **イメージ更新**   | `k set image deploy/nginx nginx=nginx:1.25` | ロールバック要求あり          |
| **スケール**     | `k scale deploy/nginx --replicas=5`         | HPA と混同しない          |
| **ラベル追加**    | `k label pod busy tier=backend`             | 選択ラベル作成             |
| **アノテーション**  | `k annotate pod busy owner="$USER"`         | 文字列にスペースあるか要注意      |
| **リソース編集**   | `k edit deploy/nginx`                       | vim で直接編集→保存→即反映    |
| **ロールアウト監視** | `k rollout status deploy/nginx`             | `rollout undo` も覚える |

---

## 5. “出たらラッキー” 10 秒ワンライナー

```bash
# 認証: ServiceAccount + RoleBinding
k create sa app-sa
k create rolebinding app-rb --clusterrole=view --serviceaccount=default:app-sa

# ノード選択 (NodeSelector/Taint/Toleration)
k taint nodes node1 env=prod:NoSchedule
# ↑ taint 削除
aint nodes node1 env-

# Probes (readiness/liveness)
k set probe deploy/nginx --readiness --get-url=http://:80/healthz

# JSONPatch
a patch deploy nginx -p='[{"op":"replace","path":"/spec/replicas","value":2}]' --type=json
```

---

## 6. “ドキッ” とするリソース対策テンプレ

### 6‑1. Liveness / Readiness Probe

```bash
# Pod を生成してから編集
k run probe-demo --image=nginx $do > probe.yaml
```

```yaml
spec:
  containers:
  - name: nginx
    image: nginx
    livenessProbe:
      httpGet:
        path: /healthz
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /
        port: 80
```

**Tip:** `initialDelaySeconds` を忘れたら `kubectl explain container.livenessProbe`。

### 6‑2. NodeAffinity / PodAffinity

```bash
k create deploy affinity-demo --image=busybox $do > aff.yaml
```

```yaml
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values: ["worker-1"]
        podAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              topologyKey: kubernetes.io/hostname
              labelSelector:
                matchLabels:
                  app: frontend
```

**Tip:** `required` vs `preferred` を区別。

### 6‑3. Taints / Tolerations

```bash
# taint 追加
a taint nodes master key1=value1:NoSchedule
# Toleration 付き Pod
k run tol-demo --image=busybox $do > tol.yaml
```

```yaml
spec:
  tolerations:
  - key: key1
    operator: Equal
    value: value1
    effect: NoSchedule
```

**Tip:** taint 削除は `k taint nodes master key1-`。

**Memo:** Taints はノード側が “来るな”、Affinity は Pod 側が “行きたい”。タイトな制限を掛けたいなら **taint + toleration**、やんわり誘導するなら **affinity**。

nodeSelector の進化版（複数条件 & ソフト要求も可）

### 6‑4. NetworkPolicy (Ingress / Egress)

```bash
k create ns np-demo
k run busy --image=busybox -n np-demo --labels app=busy --command -- sleep 3600
k create networkpolicy allow-svc -n np-demo --pod-selector=app=busy $do > np.yaml
```

```yaml
spec:
  podSelector:
    matchLabels:
      app: busy
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: api
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
    ports:
    - protocol: TCP
      port: 443
  policyTypes: ["Ingress", "Egress"]
```

**Tip:** `policyTypes` を必ず書く。

### 6‑5. StorageClass & PVC

```bash
cat <<'EOF' > pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: standard
  resources:
    requests:
      storage: 1Gi
EOF
```

**Tip:** `kubectl get sc` で SC 名を確認。

### 6‑6. SecurityContext

```bash
k run sec-demo --image=busybox $do > sec.yaml
```

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    fsGroup: 2000
  containers:
  - name: busybox
    image: busybox
    securityContext:
      capabilities:
        add: ["NET_ADMIN"]
```

### 6‑7. ServiceAccount & (Cluster)RoleBinding

```bash
k create sa app-sa
k create role view-pods --verb=get,list,watch --resource=pods $do > role.yaml
k create rolebinding view-pods-rb --role=view-pods --serviceaccount=default:app-sa $do > rb.yaml
```

---

## 7. 本番で“あれ？”となったら

1. **`kubectl explain <path>`** で公式カンニングペーパー
2. Imperative `$do` で雛形 → vim 編集 → `k apply -f <file>`
3. `source <(kubectl completion bash)` で補完を忘れずに

---

## 8. ポートフォワード & 一時 curl Pod

```bash
# ポートフォワード
k port-forward svc/my-svc 8080:80   # Service 指定
k port-forward pod/my-pod 8080:8080 # Pod 直指定 (debug)

# 一時 curl Pod
k run curl --image=curlimages/curl -it --rm --restart=Never -- sh
```

---

## 9. 訓練すべきことチェックリスト

| やらないと損なこと                                                  | 理由                                                                           |
| ---------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `kubectl get pods -o wide`                                 | **ノード配置・IP・Restart 数** を俯瞰し、異常候補を即発見                                         |
| `kubectl describe` で **個別 Events** を確認                     | PVC/PV バインド失敗・Probe failure など **リソース単位** の原因を特定                             |
| `kubectl logs` で Crash 原因追跡                                | args/command ミス・イメージ不整合を直接確認 (`--previous` 併用)                               |
| `kubectl events --types=Warning` で **Namespace/クラスタ横断** 監視 | 異常が全体で頻発していないかを時系列で把握                                                        |
| Service selector ズレ確認                                      | `kubectl get ep` / `kubectl get svc -o yaml` で Endpoints と Selector の不一致を可視化 |
| RBAC 失敗確認                                                  | `kubectl auth can-i` で Forbidden を即チェック                                      |
| 修正後の動作確認                                                   | `kubectl exec` / 一時 `curl` Pod で **実リクエストが通るか** を検証                          |

## 10. `kubectl explain` ワンライナー早見表 `kubectl explain` ワンライナー早見表

| カテゴリ                         | 見たいフィールド                    | explain コマンド                                                                   | 覚えどころ                                     |
| ---------------------------- | --------------------------- | ------------------------------------------------------------------------------ | ----------------------------------------- |
| **🛡 Security & RBAC**       | SecurityContext ✅           | `kubectl explain pod.spec.containers.securityContext.allowPrivilegeEscalation` | デフォルト `true`。CKA/CKS では `false` 推奨        |
|                              | Capabilities ✅              | `kubectl explain pod.spec.containers.securityContext.capabilities.add`         | `add:` / `drop:` が兄弟                      |
|                              | ServiceAccountName★         | `kubectl explain pod.spec.serviceAccountName`                                  | 省略時は `<default>`                          |
| **🔧 Env / Config / Secret** | Env 配列                      | `kubectl explain pod.spec.containers.env`                                      | 配列なので `- name:` で始める                      |
|                              | ConfigMap as Volume★        | `kubectl explain pod.spec.volumes.configMap`                                   | `items:` でキー→ファイル名                        |
|                              | ConfigMap as Env★           | `kubectl explain pod.spec.containers.env.valueFrom.configMapKeyRef`            | 単キーは KeyRef／丸ごとは `envFrom.configMapRef`   |
|                              | Secret as Volume★           | `kubectl explain pod.spec.volumes.secret`                                      | `defaultMode:` 0400→0644 など               |
|                              | Secret as Env★              | `kubectl explain pod.spec.containers.env.valueFrom.secretKeyRef`               | `.data.*` は Base64                        |
| **🚑 Health Checks**         | LivenessProbe★              | `kubectl explain pod.spec.containers.livenessProbe`                            | NG で **Pod 再起動**                          |
|                              | ReadinessProbe★             | `kubectl explain pod.spec.containers.readinessProbe`                           | 未 Ready は **Service 除外**                  |
|                              | StartupProbe★               | `kubectl explain pod.spec.containers.startupProbe`                             | 起動完了後に Live/Ready 有効                      |
| **📦 Workloads**             | RollingUpdate ✅             | `kubectl explain deployment.spec.strategy.rollingUpdate`                       | `maxSurge` / `maxUnavailable`             |
| **🌐 Networking & Service**  | Service.targetPort ✅        | `kubectl explain service.spec.ports.targetPort`                                | `port` ↔ `targetPort` 混同注意                |
|                              | Service.type★               | `kubectl explain service.spec.type`                                            | `ClusterIP` / `NodePort` / `LoadBalancer` |
|                              | NodePort 番号★                | `kubectl explain service.spec.ports.nodePort`                                  | 自動割当て 30000-32767                         |
|                              | Ingress backend (v1)        | `kubectl explain ingress.spec.rules.http.paths.backend.service`                | `service.name` / `service.port`           |
| **🔒 NetworkPolicy**         | policyTypes ✅               | `kubectl explain networkpolicy.spec.policyTypes`                               | `Ingress`, `Egress`／省略時 All               |
|                              | egress ✅                    | `kubectl explain networkpolicy.spec.egress`                                    | `to:` と `ports:` を同階層で                    |
| **🗄 Storage**               | PVC.storageClassName ✅      | `kubectl explain pvc.spec.storageClassName`                                    | `""` で SC 無効宣言                            |
|                              | PV.reclaimPolicy★           | `kubectl explain persistentvolume.spec.persistentVolumeReclaimPolicy`          | `Retain` / `Delete` / `Recycle(旧)`        |
|                              | StorageClass.reclaimPolicy★ | `kubectl explain storageclass.reclaimPolicy`                                   | SC 側で既存 PV の挙動を上書き                        |
| **⏱ Jobs & CronJobs**        | Job.activeDeadlineSeconds   | `kubectl explain job.spec.activeDeadlineSeconds`                               | Job 全体タイムアウト                              |
|                              | CronJob.history ★           | `kubectl explain cronjob.spec.successfulJobsHistoryLimit`                      | `failedJobsHistoryLimit` とペア              |
| **⚖️ LimitRange**            | default / defaultRequest    | `kubectl explain limitrange.spec.limits.default`                               | `defaultRequest` も兄弟キー                    |

---

> **TL;DR**
> **k create / run（＋ `$do`）→ vim → k apply** で YAML 生成・編集
> **k get/describe/logs/exec** で調査 → **k set/patch/rollout** で修正

これら 2 本柱を脊髄反射で打てれば CKAD の 80 % は取れます。
