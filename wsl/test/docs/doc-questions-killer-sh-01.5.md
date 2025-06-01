了解しました。先ほど提示した 12 問を **Q23 〜 Q34** に振り直して再掲します。
内容・スタータ YAML は同一で、番号だけ変更しています。

---

## Q23 CronJob ―「orbit-backup」

<details>
<summary>① 問題文</summary>

* **Namespace `comet`** に CronJob `orbit-backup` を作成
* image `busybox:1.31.0`, cmd `sh -c "date >> /var/log/orbit.log"`
* スケジュール `*/5 * * * *`, 成功 3 / 失敗 1 の履歴保持
* 5 分以内に 1 Job 以上完了していることを確認

</details>

```yaml
# q23-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: comet
```


---



## Q26 Ambassador + PDB ―「starlight-api」

```yaml
# q26-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: starlight
```

<details><summary>① 問題文</summary>

* Deployment `starlight-api` (replicas 4) — backend + ambassador の 2 コンテナ
* backend: `httpd:2.4.41-alpine` (port 80)
* ambassador: `curlimages/curl:8.8.0`, env `BACKEND_URL=http://localhost:80`
* Pod 内通信確認後、PDB `pdb-starlight` (`minAvailable: 3`) を設定

</details>

---

## Q27 HPA & LimitRange ―「pulse-api」

```yaml
# q27-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: pulse
```

<details><summary>① 問題文</summary>

* Deployment `pulse-api` (replicas 2, nginx 1.25-alpine)
* requests 50 m / limits 200 m
* Namespace に LimitRange で default requests/limits を設定
* HPA 2-5 replicas, CPU 70 % でオートスケールを検証

</details>

---

## Q28 Canary ロールアウト ―「nova-frontend」

```yaml
# q28-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: nova
---
# q28-deploy-v1.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nova-frontend
  namespace: nova
spec:
  replicas: 4
  selector: { matchLabels: { app: nova-frontend } }
  template:
    metadata: { labels: { app: nova-frontend } }
    spec:
      containers:
        - name: nginx
          image: nginx:1.21-alpine
          ports: [{ containerPort: 80 }]
```

<details><summary>① 問題文</summary>

* 既存 Deploy を `nginx:1.25-alpine` へ 25 % Canary 更新
* strategy `maxSurge: 1`, `maxUnavailable: 0`
* rollout 終了後に revision を確認

</details>

---

## Q29 RBAC & ImagePullSecret ―「deep-reader」

```yaml
# q29-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: deep
```

<details><summary>① 問題文</summary>

* ServiceAccount `deep-sa`、Role/RoleBinding で pods/log & exec 権限付与
* docker-registry Secret `myregistry-cred` を pull secret として紐付け
* SA 使用 Pod `deep-reader` を起動し exec でログ取得をテスト

</details>

---

## Q30 Probes + Downward API + Ephemeral Debug ―「metrics-svc」

```yaml
# q30-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: metrics
```

<details><summary>① 問題文</summary>

* Deployment `metrics-svc`, nginx 1.25, replicas 2
* StartupProbe `/healthz`, LivenessProbe 同一エンドポイント
* Downward API で Pod 名・Node 名・CPU request を env 注入
* `kubectl debug` で EphemeralContainer から値を確認

</details>

---

## Q31 Ingress (TLS) & ExternalName ―「portal-edge」

```yaml
# q31-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: portal
```

<details><summary>① 問題文</summary>

* Service `edge-api` (80)
* Ingress `portal-ing` — host `edge.example.com`、TLS secret `edge-tls`
* ExternalName Service `docs-svc` → `example.readthedocs.io`
* `curl -H "Host: edge.example.com" https://<INGRESS-IP>` で 200 を確認

</details>

---

## Q32 詳細 NetworkPolicy ―「venus-mesh」

```yaml
# q32-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: venus
---
# q32-deployments.yaml  ← 3 つの Deploy (api / frontend / db) は前回と同じ
```

<details><summary>① 問題文</summary>

* NetworkPolicy `np-venus`

  * frontend → api (8080/TCP) 許可
  * api → db (5432/TCP) 許可
  * その他の Ingress/Egress は拒否
  * DNS (UDP/TCP 53) は全方向許可

</details>

---



---



---

### ファイル一覧（サンプル）

```
q23-namespace.yaml
q24-namespace.yaml
q25-namespace.yaml
q26-namespace.yaml
q27-namespace.yaml
q28-namespace.yaml
q28-deploy-v1.yaml
q29-namespace.yaml
q30-namespace.yaml
q31-namespace.yaml
q32-namespace.yaml
q32-deployments.yaml
q33-namespace.yaml
q34-namespace.yaml
```

これで問題番号が **23 – 34** となりました。
必要に応じてさらに調整や解答例のリクエストをお知らせください！

## Killer.sh 模試スタイル：**カナリア・ロールアウト課題（Q35）**

---

### ① 問題文 【所要 15 – 20 分想定】

> **Solve on instance:** `ssh ckad9999`

1. **Namespace `orion`** に既存 Deployment **`orion-api`** が稼働しています
   （レプリカ **5**, イメージ **`nginx:1.21-alpine`**）。

2. 新バージョン **`nginx:1.25-alpine`** を **“20 % カナリア”** で段階的に導入してください。

   * **Step 1 – Canary**

     * 新イメージを **1 Pod** （全体の 20 %）だけに展開。
     * 旧イメージ 4 Pod ＋ 新イメージ 1 Pod となることを `kubectl get rs` で確認。
   * **Step 2 – Full Rollout**

     * 動作確認が取れたら、残り 80 % も新イメージへ切り替え、
       Deployment が **全 5 Pod 新バージョン** で安定している状態に仕上げてください。

3. RollingUpdate 設定は

   * **`maxSurge: 1`**, **`maxUnavailable: 0`**
     を指定すること。

4. 最終的に

   * `kubectl rollout status deploy/orion-api` が *successfully rolled out* を出力し、
   * `kubectl describe deploy/orion-api` で **`Image: nginx:1.25-alpine`** が確認できる
     ところまで実施してください。

---

### ② スタータ YAML

```yaml
# q35-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: orion
---
# q35-deploy-v1.yaml   ← まず apply して旧バージョンを動かす
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orion-api
  namespace: orion
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: orion-api
  template:
    metadata:
      labels:
        app: orion-api
    spec:
      containers:
        - name: nginx
          image: nginx:1.21-alpine
          ports:
            - containerPort: 80
```

> **ヒント**
>
> * 手順例（学習用）
>
>   1. `kubectl set image deployment/orion-api nginx=nginx:1.25-alpine --record`
>   2. `kubectl rollout status --watch deployment/orion-api`
>   3. `kubectl rollout pause deployment/orion-api` で 1 Pod だけに止める
>   4. 動作確認後 `kubectl rollout resume deployment/orion-api`
> * あるいは `--max-surge / --max-unavailable` を駆使して
>   ReplicaSet 比率を 4:1 → 5:0 に段階制御しても可。

この YAML を適用後、課題のカナリア・ロールアウトを実施してください。


auth can-i
rolling-update

### 新規追加 ― **Killer.sh レベル演習問題**

---

## Q36 RBAC & `kubectl auth can-i` チェック ―「galaxy-viewer」

### ① 問題文

> **Solve on instance:** `ssh ckadXXXX`

1. **Namespace `auth-lab`** に ServiceAccount **`galaxy-viewer`** を作成してください。
2. 初期状態で、**この SA では `get` 以外の Kubernetes API を実行できない** はずです。

   * `kubectl auth can-i --as system:serviceaccount:auth-lab:galaxy-viewer delete pods -n auth-lab`
     を実行し、**`no`** が返ることを確認してください。
3. 続いて、ClusterRole/RoleBinding を組み合わせ、
   **`pods/log` と `pods/exec`** に限り許可を与えてください
   （`create`, `delete` などは引き続き禁止）。
4. もう一度 `kubectl auth can-i` を実行し、

   * `get` → **yes**
   * `logs` → **yes**
   * `delete` → **no**
     がそれぞれ返ることを確認してください。
5. 最後に、確認に使用した 3 行の `kubectl auth can-i …` コマンドを
   **`~/auth-lab/verify.sh`** に記述し、実行権限を付与しておいてください。

### ② スタータ YAML

```yaml
# q36-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: auth-lab
---
# q36-pod.yaml   ← ログ／exec テスト用のサンプル Pod
apiVersion: v1
kind: Pod
metadata:
  name: demo-pod
  namespace: auth-lab
spec:
  containers:
    - name: app
      image: busybox:1.31.0
      command: ["sh", "-c", "while true; do date; sleep 30; done"]
```

---

## Q37 RollingUpdate で “瞬断ゼロ” バージョンアップ ―「zen-ui」

### ① 問題文

1. **Namespace `rolling-demo`** には Deployment **`zen-ui`**（replicas 6, image `nginx:1.23-alpine`）が稼働しています。
2. サイトの SLA が厳格なため、**同時に落ちる Pod を 1 つだけ** に抑えつつ、新イメージ **`nginx:1.26-alpine`** へローリングアップデートしてください。

   * `spec.strategy.rollingUpdate` を

     * **`maxUnavailable: 1`**
     * **`maxSurge: 2`**
       にセットすること。
3. アップデート途中で

   ```bash
   kubectl get pods -l app=zen-ui -w -n rolling-demo
   ```

   を実行し、常に **5 つ以上の Pod が Running** 状態を保っていることを確認してください（※自分で目視確認）。
4. ロールアウト完了後、

   * `kubectl rollout history deployment/zen-ui -n rolling-demo` で **Revision 2** のみが `nginx:1.26-alpine` になっていること
   * `kubectl rollout status deployment/zen-ui -n rolling-demo` が *successfully rolled out* を返すこと
     をスクリーンショット、またはコマンド履歴に残しておいてください。

### ② スタータ YAML　

```yaml
# q37-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: rolling-demo
---
# q37-deploy-v1.yaml   ← まず apply して旧バージョンを稼働させる
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zen-ui
  namespace: rolling-demo
spec:
  replicas: 6
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: zen-ui
  template:
    metadata:
      labels:
        app: zen-ui
    spec:
      containers:
        - name: nginx
          image: nginx:1.23-alpine
          ports:
            - containerPort: 80
```

---

**使い方メモ**

1. まずスタータ YAML を `kubectl apply -f …` で流し込み既存環境を構築。
2. その上で問題指示どおりに Role/RoleBinding 追加や `kubectl set image`→`rollout` 操作を行ってください。

この 2 問で **`kubectl auth can-i` の権限制御** と **実践的 Rolling Update** の両方を演習できます。

## 置き換え問題 ― **Q24  Taints & Tolerations ―「orbit-batch」**

（元 DaemonSet“space-exporter”はスコープ外にしたため削除）

---

### ① 問題文【Killer.sh レベル／10-15 min 想定】

> **Solve on instance:** `ssh ckad9999`

1. **前提**
   クラスタにはすでに 2 種類のノードがあります。

   * **バッチ用ノード** → `node-role.kubernetes.io/batch=true` というラベル＆
     タaint **`dedicated=batch:NoSchedule`** が設定済み
   * **通常ノード** → タaint 無し

2. **Namespace `orbit`** に Deployment **`orbit-batch`** を作成してください。

   * replicas **3**
   * image **`busybox:1.31.0`**
   * command: `sh -c "while true; do echo batch >> /proc/1/fd/1; sleep 30; done"`

3. **要件**

   * **Pod は “バッチ用ノード” のみにスケジュール** されること
     （`dedicated=batch:NoSchedule` を許容する **Toleration** を付与）
   * ただしクラスタにバッチノードが 1 台しか無い場合でも
     **最大 2 Pod までしか同じノードに載らない** よう、
     **Pod Anti-Affinity** で `hostname` 別スプレッドを指定すること。

4. 作成後、以下を実行して結果をスクリーンショット（またはコマンド履歴）に残してください。

   ```bash
   kubectl get pods -o wide -n orbit
   # 期待: それぞれ batch ノード上。1 ノードに 2 Pod まで
   kubectl describe node <BATCH_NODE> | grep Taints
   # "dedicated=batch:NoSchedule" が確認できる
   ```

---

### ② スタータ YAML

```yaml
# q24-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: orbit
---
# q24-taint-demo.yaml  ← 実環境に taint が無い場合は参考用
# ※演習用に一時的に taint を付けたいときに apply
# kubectl taint nodes <node-name> dedicated=batch:NoSchedule
```

> **ヒント**
>
> * Toleration テンプレ
>
>   ```yaml
>   tolerations:
>     - key: "dedicated"
>       operator: "Equal"
>       value: "batch"
>       effect: "NoSchedule"
>   ```
> * Pod Anti-Affinity（ホスト名分散）
>
>   ```yaml
>   affinity:
>     podAntiAffinity:
>       requiredDuringSchedulingIgnoredDuringExecution:
>         - labelSelector:
>             matchLabels:
>               app: orbit-batch
>           topologyKey: "kubernetes.io/hostname"
>   ```

---

### ファイル一式（例）

```
q24-namespace.yaml
q24-deploy.yaml          # ← 受験者が完成させる
```

この Q24 を DaemonSet の代わりに追加し、
**Taints & Tolerations + (おまけで) Pod Anti-Affinity** を実戦形式で練習できます。


