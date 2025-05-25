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

## Q24 StatefulSet + HeadlessSvc ―「nebula-redis」

<details><summary>① 問題文</summary>

* Namespace `nebula`, StatefulSet `nebula-redis` (replicas 3)
* image `redis:7.2-alpine`, port 6379/TCP
* Pod ごとに 2 Gi RWO PVC を動的生成
* Headless Service `nebula-redis` で Stateful DNS を有効化

</details>

```yaml
# q24-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: nebula
```

---

## Q25 DaemonSet ―「space-exporter」

<details><summary>① 問題文</summary>

* Namespace `galaxy`, DaemonSet `space-exporter`
* image `prom/node-exporter:v1.8.1`, hostPort 9100
* ノードラベル `node-role.kubernetes.io/gpu=true` が付く GPU ノードには配置しない

</details>

```yaml
# q25-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: galaxy
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

## Q33 Affinity / Taints & Priority ─「cosmo-worker」

```yaml
# q33-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: cosmo
```

<details><summary>① 問題文</summary>

* PriorityClass `cosmo-high` value 100000
* Deployment `cosmo-worker` (busybox, replicas 3)

  * preferred zone=us-east, fallback us-west
  * nodeSelector `kubernetes.io/arch=amd64`
  * toleration for taint `dedicated=batch:NoSchedule`

</details>

---

## Q34 StorageClass & Volume Expansion ―「terra-store」

```yaml
# q34-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: terra
```

<details><summary>① 問題文</summary>

* StorageClass `terra-gold`（allowVolumeExpansion: true）を新規作成
* PVC `terra-pvc` 1 Gi→Pod `terra-app` (nginx) にマウント
* 実行後に PVC を 3 Gi へ拡張し、Pod 内 `df -h` でサイズ増加を確認

</details>

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
