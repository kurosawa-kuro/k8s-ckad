以下のようにドキュメントを調整しました。**`/bin/sh` に関する参照方法**をより明確にし、**コマンドの実行**や関連するリソース設定に焦点を当てて整理しています。

---

## ✅ **CKADで出題される可能性が高いリソース（`kubectl explain` で確認した場合の不十分さと公式ドキュメント活用）**

### **`/bin/sh` がわからなくなった場合**

`/bin/sh` についての詳細は、「command:」キーワードで検索し、**[Run a command in a shell](https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/)** セクションを参照すると確認できます。

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: command-runner 
  name: command-runner
spec:
  containers:
  - image: busybox  # 軽量なイメージを使用
    name: command-runner
    resources: {}
    command: ["/bin/sh","-c", "while true; do echo hello; sleep 10; done"]  # コンテナが起動した際に実行されるコマンド
  dnsPolicy: ClusterFirst 
  restartPolicy: Never  # Podの再起動ポリシー。`Never` で、コンテナが終了しても再起動は行われません
status: {}
```

---

### ① **Podのライフサイクルと関連設定**

#### livenessProbe / readinessProbe / startupProbe

* `kubectl explain` では型しか分からず、**httpGet/exec/tcpSocket の使い分け方や典型構文例が出てこない**。
* → 公式：[livenessProbe設定](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)

**サンプル:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-readiness-probe  # Podの名前。livenessProbeとreadinessProbeの設定を試すためのPod
spec:
  containers:
    - name: nginx  # コンテナ名。`nginx` コンテナを使用
      image: nginx  # 使用するコンテナイメージ
      livenessProbe:  # Podの健康状態を確認するlivenessProbeの設定
        httpGet:  # HTTP GETリクエストを使用して状態を確認
          path: /healthz  # 健康状態を確認するパス
          port: 80  # 使用するポート
        initialDelaySeconds: 3  # Podが起動してから3秒後に確認を開始
        periodSeconds: 5  # 5秒ごとに健康状態を確認
```

#### activeDeadlineSeconds の構造位置に注意

* **`activeDeadlineSeconds` は、PodSpecのトップレベルの設定**として指定されます。
* これが設定されていると、Podの**実行時間が制限され**、指定時間を超えるとPodが強制的に終了します。**`spec.containers` 内ではなく、`spec` の直下に位置します**。
* → 公式：[activeDeadlineSecondsの設定](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#active-deadline-seconds)

**サンプル:**

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: every-five
spec:
  schedule: "*/5 * * * *"  # ジョブを5分おきに実行
  startingDeadlineSeconds: 20  # ジョブの開始遅延許容時間（秒）。スケジュール時間から20秒以内にジョブが開始しないと無視される
  concurrencyPolicy: Forbid  # ジョブの重複実行を禁止（前回のジョブが終了するまで新しいジョブを開始しない）
  successfulJobsHistoryLimit: 3  # 成功したジョブの履歴を最大3件保持
  failedJobsHistoryLimit: 1  # 失敗したジョブの履歴を最大1件保持
  jobTemplate:
    spec:
      activeDeadlineSeconds: 30  # ジョブの実行最大時間（秒）。30秒以内に終了しない場合、強制終了される
      ttlSecondsAfterFinished: 60  # ジョブ終了後、60秒後にリソース（Podなど）を削除する
      template:
        spec:
          restartPolicy: Never  # ジョブが失敗した場合、Podを再起動しない
          containers:
          - name: hello
            image: busybox  # コンテナイメージとしてbusyboxを使用
            command:
              - "/bin/sh"
              - "-c"
              - "echo 'Starting job'; echo 'hello-from-cron'; sleep 5; echo 'Job completed'"
```

---

### ② **リソースのスケーリングと制限**

#### PodDisruptionBudget / HorizontalPodAutoscaler / ResourceQuota / LimitRange

* `kubectl explain` ではポリシーの意味や制限の戦略がわからない。
* → 公式：[PodDisruptionBudget設定](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)
* → 公式：[HorizontalPodAutoscaler設定](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

**サンプル (PodDisruptionBudget):**

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-app-pdb  # PodDisruptionBudgetの名前。Webアプリの可用性を守るため
spec:
  minAvailable: 2  # 常に最低2つのPodが稼働していることを保証
  selector:
    matchLabels:
      app: web-app  # `web-app` ラベルがついているPodを対象
```

**サンプル (HorizontalPodAutoscaler):**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-server-hpa  # HorizontalPodAutoscalerの名前。APIサーバーのスケーリング管理
spec:
  scaleTargetRef:  # スケール対象のリソース（ここではDeployment）
    apiVersion: apps/v1
    kind: Deployment
    name: api-server  # 対象のDeployment名
  minReplicas: 1  # 最小レプリカ数（Pod数）
  maxReplicas: 5  # 最大レプリカ数（Pod数）
  metrics:
  - type: Resource
    resource:
      name: cpu  # スケーリングの基準となるリソース
      target:
        type: Utilization
        averageUtilization: 50  # CPU利用率が50%を超えるとスケールアップ
```

**サンプル (ResourceQuota):**

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota  # ResourceQuotaの名前。開発環境でリソースを制限
  namespace: dev  # `dev` 名前空間に適用
spec:
  hard:
    requests.cpu: "2"  # 最大CPUリソース要求量を2CPUに制限
    requests.memory: 4Gi  # 最大メモリリソース要求量を4Giに制限
    pods: "10"  # 最大Pod数を10に制限
```

---

### ③ **コンテナの設定と共有**

#### initContainers + shareProcessNamespace

* `initContainers` の使い方や共通ファイル共有、`emptyDir`との絡みなどが典型パターンとして紹介されている。
* → 公式：[initContainersの使い方](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)

**サンプル:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-init-container
spec:
  initContainers:
    - name: init-mydb
      image: busybox
      command: ['sh', '-c', 'echo waiting for db; sleep 10']
  containers:
    - name: nginx
      image: nginx
      volumeMounts:
        - name: shared-data
          mountPath: /usr/share/nginx/html
  volumes:
    - name: shared-data
      emptyDir: {}
```

#### volumeMounts / volumes の各種型（configMap, secret, emptyDir, hostPath）

* `emptyDir` や `hostPath` の使い方やシナリオが `kubectl explain` では不足していることが多い。
* → 公式：[volumesの設定](https://kubernetes.io/docs/concepts/storage/volumes/)

**サンプル (emptyDir):**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-emptydir
spec:
  containers:
    - name: nginx
      image: nginx
      volumeMounts:
        - mountPath: "/data"
          name: mydata
  volumes:
    - name: mydata
      emptyDir: {}
```

---

### ④ **スケジュールとテイント（Taint）**

#### taint

* **Taint** は、ノードに**制約を追加**するための設定です。これにより、特定のPodがそのノードにスケジュールされるのを防ぐことができます。
* `kubectl taint` コマンドを使って、ノードに**特定の制約**を追加します。例えば、以下のコマンドで、`foo` ノードに対して `dedicated=special-user:NoSchedule` というタイントを設定します：

  ```bash
  kubectl taint nodes foo dedicated=special-user:NoSchedule
  ```

  これにより、**`special-user` に関連するPod**はこのノードにスケジュールされなくなります。

**サンプル (taintの設定):**

```bash
kubectl taint nodes foo dedicated=special-user:NoSchedule
```

#### Tolerationsの設定

* `tolerations` を使うと、特定のPodが**タイント付きノード**にスケジュールされることを許可できます。`tolerations` は、Podの`spec`セクションで設定します。

**サンプル (tolerationsの設定):**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-toleration
spec:
  tolerations:  # タイントを許容するための設定
    - key: "dedicated"  # タイントのキー。ここでは「dedicated」が指定されています
      operator: "Equal"  # オペレーター。「Equal」はキーと値が一致する場合に許容される
      value: "special-user"  # 許容する値。「special-user」と一致するタイントを許容
      effect: "NoSchedule"  # `NoSchedule` 効果を持つタイントを許容。Podが特定のノードにスケジュールされるのを許可する
  containers:
    - name: nginx  # コンテナの名前。`nginx` という名前を付けています
      image: nginx  # 使用するコンテナイメージ。`nginx` イメージを指定
```

---

### ⑤ **ジョブとCronJobの設定**

#### Job / CronJob の `successfulJobsHistoryLimit`, `failedJobsHistoryLimit`, `concurrencyPolicy`

* `kubectl explain` では意図が読み取れず、「何を制御しているのか」すら曖昧。
* → 公式：[CronJobの設定](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)

**サンプル (CronJob):**

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: my-cronjob
spec:
  schedule: "*/5 * * * *"  # 5分ごとにジョブを実行
  successfulJobsHistoryLimit: 10  # 成功したジョブの履歴を最大10件保持
  failedJobsHistoryLimit: 5  # 失敗したジョブの履歴を最大5件保持
  concurrencyPolicy: Forbid  # 前回のジョブが完了するまで新しいジョブを開始しない
  jobTemplate:
    spec:
      startingDeadlineSeconds: 60  # ジョブがスケジュールされた時間から60秒以内に開始されないと無視される
      completions: 1  # ジョブが成功と見なされるために必要な成功したPodの数（ここでは1つ）
      parallelism: 1  # 同時に実行するPodの数（ここでは1つのみ）
      backoffLimit: 2  # ジョブの再試行回数。失敗した場合、最大2回まで再試行
      template:
        spec:
          containers:
          - name: my-container
            image: busybox 
            command:
            - "/bin/sh"  # 実行するシェルコマンド
            - "-c" # シェルに、指定した文字列を コマンドとして実行する ことを指示するオプション
            - "echo Hello, world"  # 実行するコマンド（標準出力に"Hello, world"を表示）
          restartPolicy: OnFailure  # ジョブが失敗した場合のみ再起動
```

---

### ⑥ **ネットワークとセキュリティ**

#### NetworkPolicy

* `podSelector` や `ingress.from.namespaceSelector` などは `kubectl explain` だと表面構造だけ。
* **Ingressに関する設定は、NetworkPolicyの一部ではなく、ネットワークトラフィックを制御するためのリソースとして区別して理解する**必要があります。
* → 公式：\[NetworkPolicy設定]\([https://kubernetes.io/docs/concepts/services-networking/network-p](https://kubernetes.io/docs/concepts/services-networking/network-p)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: db  # "db"役割のPodに対するIngressの制御を行います
  policyTypes:
  - Ingress  # Ingressトラフィックのみを制御
  ingress:
  - from:
    - ipBlock:
        cidr: 172.17.0.0/16  # 172.17.0.0/16 のIPブロックからの通信を許可
        except:
        - 172.17.1.0/24  # 172.17.1.0/24 のIPブロックを除外
    - namespaceSelector:
        matchLabels:
          project: myproject  # myprojectプロジェクトに属するnamespaceからの通信を許可
    - podSelector:
        matchLabels:
          role: frontend  # "frontend"役割のPodからの通信を許可
    ports:
    - protocol: TCP
      port: 6379  # 6379ポート（例えばRedisなどのサービス）への通信を許可
```
