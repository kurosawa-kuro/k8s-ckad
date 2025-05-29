cd ~/dev/k8s-ckad/wsl/test
./-setup.sh

cd /home/wsl/dev/k8s-ckad/wsl/script
make reset-heavy
cd /home/wsl/dev/k8s-ckad/wsl/test

alias k=kubectl
export do="--dry-run=client -o yaml"
kubectl config set-context --current --help | grep -A3 -B3 -- --namespace
alias kn='kubectl config set-context --current --namespace '
alias kcfg='kubectl get cm,secret,sa,role,pvc,svc,events -n'

kubectl config set-context --current --help | grep -A3 -B3 -- --namespace
kubectl create job my-job --image=busybox:1.31.0 --namespace=neptune --dry-run=client -o yaml -- /bin/sh -c "sleep 2 && echo done" > job.yaml
kubectl get secret neptune-sa-v2-token -n neptune -o jsonpath={.data.token} | base64 -d
kubectl run pod6 --image=busybox:1.31.0 --restart=Never --dry-run=client -o yaml --command -- /bin/sh -c 'touch /tmp/ready && sleep 1d' > pod6-skel.yaml                 # ← ファイルに保存
kubectl explain pod --recursive | grep allowPrivilegeEscalation
kubectl explain pod.spec.containers.securityContext.allowPrivilegeEscalation

kubectl run project-plt-6cc-api --image=nginx:1.17.3-alpine --restart=Never --labels=project=plt-6cc-api --port=80 -n pluto
kubectl expose pod project-plt-6cc-api --name=project-plt-6cc-svc --port=3333 --target-port=80 --type=ClusterIP -n pluto

# 3. 一時コンテナから Service 経由アクセスし、レスポンスをホストへ保存
kubectl run curl -n pluto --rm -it --restart=Never --image=curlimages/curl -- sh -c 'curl -s project-plt-6cc-svc:3333' > service_resp.html

kubectl create secret generic secret1 --from-literal=user=test --from-literal=pass=pwd --dry-run=client -oyaml -n moon > secret1.yaml
kubectl get secret secret2 -n moon -o jsonpath={.data.config} | base64 -d

kubectl explain pod.spec.containers.env

kubectl expose deployment web-moon --name=web-moon --port=80 --target-port=80 -n moon
kubectl get svc web-moon -n moon
kubectl run curl -n moon --rm -it --restart=Never --image=curlimages/curl -- curl -s http://web-moon:80


kubectl get pods -l app=cleaner -n mercury
NEW_POD=$(kubectl get pod -l app=cleaner -n mercury -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}')
kubectl logs -f "$NEW_POD" -c logger-con -n mercury

POD_IP=$(kubectl get pod -l app=test-init -n mars -o jsonpath='{.items[0].status.podIP}')
kubectl run curl -n mars --rm -it --restart=Never --image=curlimages/curl -- curl -s http://$POD_IP:80

kubectl run curl -n mars --rm -it --restart=Never --image=curlimages/curl -- curl -s http://manager-api-svc.mars:4444

kubectl get nodes -o wide
NODE_IP=192.168.49.2
curl http://$NODE_IP:30100

kubectl get pod -n sun -l 'type in (worker,runner)'


| フェーズ   | Kubernetes で指定するフィールド                         | 役割                             |
| ------ | --------------------------------------------- | ------------------------------ |
| **入口** | `Service.spec.ports[].port`                   | クライアントがアクセスする Service のポート     |
| **出口** | `Service.spec.ports[].targetPort`             | kube-proxy が Pod に転送するときの宛先ポート |
| **着地** | `Pod.spec.containers[].ports[].containerPort` | アプリが LISTEN している実ポート           |

まとめ — “テンプレ暗記セット”
yaml
コピーする
編集する
# 1キーだけ ENV
env:
  - name: DB_PASS
    valueFrom:
      secretKeyRef:
        name: db-secret
        key: password

# Secret 丸ごと ENV
envFrom:
  - secretRef:
      name: db-secret
      prefix: DB_
yaml
コピーする
編集する
# Secret マウント
volumes:
  - name: db-secret-vol
    secret:
      secretName: db-secret          # defaultMode は任意
volumeMounts:
  - name: db-secret-vol
    mountPath: /etc/secret
    readOnly: true
この“型”を手元に置いておけば、Secret／ConfigMap／Downward API の問題は迷わずクリアできます。
今回のコマンド集と合わせて、ぜひ CKAD・Killer.sh の本番チートシートに加えてください 🚀


# c s s r p s e

====================================================================================================================================================================================================================================================================================================================================================================================================================================================================================

====================================
Q6

Question 6:
Solve this question on instance: ssh ckad5601

* **default** ネームスペースに、イメージ **`busybox:1.31.0`** の **Pod を 1 つ** 作成してください。

  * Pod 名：**`pod6`**

* Pod には **readinessProbe** を設定し、コマンド **`cat /tmp/ready`** でヘルスチェックを行います。

  * 最初の実行まで **5 秒待機**
  * 以降は **10 秒間隔** でプローブ
  * ファイル **`/tmp/ready`** が存在する場合のみコンテナを Ready と判定します。

* コンテナの起動コマンドは
  **`touch /tmp/ready && sleep 1d`**
  とし、Ready 判定用のファイルを作成してから 1 日スリープします。

Pod を作成し、正常に起動したことを確認してください。


====================================


====================================
Q10

Question 10:
Solve this question on instance: ssh ckad9043

Pluto チームはクラスタ内部用の新しい Service を必要としています。

1. **Namespace `pluto`** に **ClusterIP Service `project-plt-6cc-svc`** を作成してください。
2. この Service が公開する **Pod `project-plt-6cc-api`** も作成します。

   * イメージ: **`nginx:1.17.3-alpine`**
   * Pod のラベル: **`project: plt-6cc-api`**
3. Service のポートは **TCP 3333 → Pod 側 80** へポートリダイレクトしてください。

最後に、テンポラリの **`nginx:alpine`** Pod などを使って Service に `curl` でアクセスし、

* レスポンス内容を **`/10/service_test.html`**（ckad9043 ノード）へ保存
* さらに **`project-plt-6cc-api`** Pod のログにリクエストが記録されていることを確認し、そのログを **`/10/service_test.log`** に書き込んでください。

====================================


====================================
Q18

Question 18:
Solve this question on instance: ssh ckad5601

Namespace **`mars`** にある **ClusterIP Service `manager-api-svc`** が、
同じ名前空間の **Deployment `manager-api-deployment`** の Pod を公開できていないようです。

1. テスト方法

   * 一時的に **`nginx:alpine`** の Pod を起動し、
     `curl manager-api-svc.mars:4444` を実行して通信を確認する。

2. **設定ミスを調べて修正** し、Service 経由で Pod にアクセスできる状態にしてください。


kubectl apply -f q18-01.yaml,q18-02.yaml,q18-03.yaml,q18-04.yaml

# q18-01.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: mars

# q18-02.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: manager-api-deployment
  namespace: mars
  labels:
    app: manager-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: manager-api
  template:
    metadata:
      labels:
        app: manager-api
    spec:
      containers:
        - name: manager-api
          image: nginx:1.17.3-alpine
          ports:
            - containerPort: 80

# q18-03.yaml
apiVersion: v1
kind: Service
metadata:
  name: manager-api-svc
  namespace: mars
spec:
  type: ClusterIP
  selector:
    app: manager-api
  ports:
    - name: http
      port: 4444          # ← クライアントがアクセスするポート
      targetPort: 8888    # ← ★ Pod 側のポートと“ズレている”ため通信できない
      protocol: TCP

# q18-04.yaml
apiVersion: v1
kind: Pod
metadata:
  name: curl-test
  namespace: mars
spec:
  containers:
    - name: curl
      image: nginx:alpine
      command: ["sh", "-c", "sleep infinity"]
  restartPolicy: Never

# ❷ サービスにアクセスしてみる（まだ失敗するはず）
kubectl exec -n mars curl-test -- curl -s --max-time 3 manager-api-svc.mars:4444 || echo "接続失敗"

====================================

====================================
Q9

Question 9:
Solve this question on instance: ssh ckad9043

Namespace **`pluto`** には、現在 **`holy-api`** という Pod が 1 つだけ稼働しています。これまでは問題なく動いていましたが、Pluto チームは **信頼性向上** のために複製数を増やしたいと考えています。

1. この Pod を **Deployment** に変換し、名前は **`holy-api`**、**レプリカ数は 3** としてください。
2. Deployment 作成後、**元の Pod は削除**してください。

   * 参考用の生テンプレート（Pod 定義）は **`holy-api-pod.yaml`** にあります。
3. 新しい Deployment のコンテナには **`securityContext`** を設定し、

   * `allowPrivilegeEscalation: false`
   * `privileged: false`
     を明示してください。
4. 作成した Deployment の YAML を **`holy-api-pod.yaml`** に保存してください。


kubectl apply -f q9-01.yaml,q9-02.yaml

# q9-01.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: pluto

# q9-02.yaml
apiVersion: v1
kind: Pod
metadata:
  name: holy-api
  namespace: pluto
  labels:
    app: holy-api
spec:
  containers:
    - name: api
      image: nginx:1.23-alpine   # 例:軽量で動作確認しやすい
      ports:
        - containerPort: 80
====================================


====================================
Q14

Question 14:
Solve this question on instance: ssh ckad9043

課題: Namespace moon にある Pod secret-handler の定義を修正してください。

Secret secret1 を Namespace moon に新規作成し、下記キーを含めること。

user=test
pass=pwd

Pod では次の環境変数として参照できるようにすること。

SECRET1_USER → user
SECRET1_PASS → pass

/14/secret2.yaml にある YAML を適用して Secret secret2 を作成し、
Pod 内の /tmp/secret2 にマウントすること。

基本 YAML (/14/secret-handler.yaml) を編集し、
変更後のファイルを /14/secret-handler-new.yaml として保存すること。

両方の Secret は Namespace moon でのみ利用できるようにしてください。


# /opt/course/14/secret-handler.yaml  ← apply しない
apiVersion: v1
kind: Pod
metadata:
  name: secret-handler
  namespace: moon
  labels:
    app: secret-handler
spec:
  containers:
    - name: secret-handler
      image: busybox          # 元のイメージに置き換えて可
      command: ["sleep", "3600"]
  # ↓ ここから下は空。受験者が env / volume を追記して完成させる

# /opt/course/14/secret2.yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret2
  namespace: moon
type: Opaque
stringData:
  config: |
    key=moon
    region=space
    
====================================
Q1

DevOps チームは、クラスタ内に存在する **すべての Namespace の一覧を取得** したいと考えています。
その一覧を取得し、`~/dev/k8s-ckad/wsl/test/namespaces` というファイルに保存してください。
====================================




====================================
Q2

Question 2:
Solve this question on instance: ssh ckad5601

* **default** Namespace に、イメージ **`httpd:2.4.41-alpine`** の **Pod を 1 つ作成**してください。

  * Pod 名: **`pod1`**
  * コンテナ名: **`pod1-container`**

* 上司はときどきその Pod のステータスを手動で確認したいと考えています。
  **`kubectl` を使って Pod のステータスを出力するコマンド**を作成し、
  **ckad5601** ノードの
  `~/dev/k8s-ckad/wsl/test/pod1-status-command.sh`
  に記述してください。


====================================



====================================
Q3

Question 3:
Solve this question on instance: ssh ckad7326

**Neptune チーム**向けに **`job.yaml`** というファイルで Job のテンプレートを作成してください。

* 使用イメージ: **`busybox:1.31.0`**
* 実行コマンド: `sleep 2 && echo done`
* Namespace: **`neptune`**
* **実行回数は合計 3 回**、そのうち **2 回を並列**で実行する
* Job 名: **`neb-new-job`**
* コンテナ名: **`neb-new-job-container`**
* Job が生成する各 Pod には **`id: awesome-job`** というラベルを付ける

Job を起動し、履歴を確認できるようにしてください。


kubectl apply -f q3-01.yaml

# q3-01.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: neptune
====================================



====================================
Q4

Question 4:
Solve this question on instance: ssh ckad7326

Mercury チームから **Namespace `mercury`** 内で Helm を使って次の作業を依頼されています。

1. **`internal-issue-report-apiv1`** というリリースを削除する
2. **`internal-issue-report-apiv2`** リリースを、利用可能な **`bitnami/nginx`** チャートの新しいバージョンへアップグレードする
3. **`helm `** チャートを用いて、新しいリリース **`internal-issue-report-apache`** をインストールする

   * その際、Helm の values で **Deployment のレプリカ数を 2** に設定する
4. **`pending-install` 状態で止まっている壊れたリリース** があるので、特定して削除する


kubectl apply -f q4.yaml

# q4.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: mercury
====================================

 helm uninstall internal-issue-report-apiv1
 helm upgrade internal-issue-report-apiv2
 helm install internal-issue-report-apache bitnami/apache --set replicaCount=2

====================================
Q5

Question 5:
Solve this question on instance: ssh ckad7326

Neptune チームは、**Namespace `neptune`** に **`neptune-sa-v2`** という ServiceAccount を持っています。
この ServiceAccount に紐づく Secret の **トークン** を同僚が必要としています。
**base64 デコードしたトークン文字列**を、**ckad7326** の
`~/dev/k8s-ckad/wsl/test/q5/token`
というファイルに書き込んでください。


kubectl apply -f q5.yaml

# q5.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: neptune
---
# 2) ServiceAccount ------------------------------------------
apiVersion: v1
kind: ServiceAccount
metadata:
  name: neptune-sa-v2
  namespace: neptune
---
# 3) ServiceAccount Token Secret -----------------------------
#    controller が 'token', 'ca.crt' を自動注入する
apiVersion: v1
kind: Secret
metadata:
  name: neptune-sa-v2-token        # 好きな名前でOK
  namespace: neptune
  annotations:
    kubernetes.io/service-account.name: neptune-sa-v2
type: kubernetes.io/service-account-token



====================================







====================================
Q7 問題再現が難しいので後回し

Question 7:
Solve this question on instance: ssh ckad7326

Neptune チームの経営陣は、Saturn チームが運用していた **e コマース Web サーバ** を引き継ぐことにしました。
そのサーバを構築した管理者は既に退職しており、判明している情報は **システム名が *my-happy-shop* である** ことだけです。

1. **Namespace `saturn`** の中から、該当する Pod を探し出してください。
2. その Pod を **Namespace `neptune`** へ移動してください。

   * 一度停止して新しく起動し直しても構いません。
     （顧客はほぼいないはずなので影響はありません）


kubectl apply -f q7-01.yaml,q7-02.yaml

# q7-01.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: saturn
---
apiVersion: v1
kind: Namespace
metadata:
  name: neptune


# q7-02.yaml
apiVersion: v1
kind: Pod
metadata:
  name: webserver-sat-001
  namespace: saturn
  labels:
    id: webserver-sat-001
spec:
  containers:
    - name: nginx
      image: nginx:1.16.1-alpine
      ports: [{ containerPort: 80 }]
  restartPolicy: Always
---
apiVersion: v1
kind: Pod
metadata:
  name: webserver-sat-002
  namespace: saturn
  labels:
    id: webserver-sat-002
spec:
  containers:
    - name: nginx
      image: nginx:1.16.1-alpine
      ports: [{ containerPort: 80 }]
  restartPolicy: Always
---
apiVersion: v1
kind: Pod
metadata:
  name: webserver-sat-003                # ← これが “my-happy-shop”
  namespace: saturn
  labels:
    id: webserver-sat-003
  annotations:
    description: >-
      this is the server for the e-Commerce System my-happy-shop
spec:
  containers:
    - name: nginx
      image: nginx:1.16.1-alpine
      ports: [{ containerPort: 80 }]
  restartPolicy: Always
---
apiVersion: v1
kind: Pod
metadata:
  name: webserver-sat-004
  namespace: saturn
  labels:
    id: webserver-sat-004
spec:
  containers:
    - name: nginx
      image: nginx:1.16.1-alpine
      ports: [{ containerPort: 80 }]
  restartPolicy: Always
---
apiVersion: v1
kind: Pod
metadata:
  name: webserver-sat-005
  namespace: saturn
  labels:
    id: webserver-sat-005
spec:
  containers:
    - name: nginx
      image: nginx:1.16.1-alpine
      ports: [{ containerPort: 80 }]
  restartPolicy: Always
---
apiVersion: v1
kind: Pod
metadata:
  name: webserver-sat-006
  namespace: saturn
  labels:
    id: webserver-sat-006
spec:
  containers:
    - name: nginx
      image: nginx:1.16.1-alpine
      ports: [{ containerPort: 80 }]
  restartPolicy: Always
====================================




====================================
Q8 問題再現が難しいので後回し

Question 8:
Solve this question on instance: ssh ckad7326

Namespace **`neptune`** には **`api-new-c32`** という Deployment が既に存在します。
開発者がこの Deployment を更新しましたが、新しいバージョンは正常に起動しませんでした。

1. Deployment の **リビジョン履歴**を確認し、動作していたリビジョンを特定してロールバックしてください。
2. なぜ更新版が立ち上がらなかったのか、**エラーの原因**を調べて Team Neptune に報告してください。


kubectl apply -f q8-01.yaml,q8-02.yaml,q8-03.yaml

# q8-01.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: neptune


# q8-02.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-new-c32
  namespace: neptune
spec:
  replicas: 3
  selector:
    matchLabels: { app: api-new-c32 }
  template:
    metadata:
      labels: { app: api-new-c32 }
    spec:
      containers:
        - name: backend
          image: nginx:1.23-alpine        # ✅ pull 可能
          ports: [{ containerPort: 80 }]

# q8-03.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-new-c32
  namespace: neptune
spec:
  replicas: 3
  selector:
    matchLabels: { app: api-new-c32 }
  template:
    metadata:
      labels: { app: api-new-c32 }
      annotations:
        commit: bad-v2                  # ← ★ わざと 1 行追加して差分を確実化
    spec:
      containers:
        - name: backend
          image: nginx:9.99-does-not-exist   # ❌ ImagePullBackOff
          ports: [{ containerPort: 80 }]
====================================













====================================
Q11 後回し中 Docker周りのtest準備対策は後回し中

Question 11:
Solve this question on instance: ssh ckad9043

あなたが月例ミーティングで披露した **コンテナ技術の知見** を、Sun 部門の Build\&Release チームが必要としています。
イメージをビルドするためのファイルは **`/11/image`** に置かれており、
コンテナでは **標準出力に情報を出す Go アプリケーション** が動きます。
以下の作業を行ってください。

> **注意**
> すべてのコマンドはユーザ **`candidate`** で実行してください。
> Docker を使うときは **`sudo docker`** を忘れずに。

1. **Dockerfile** を修正し、環境変数 **`SUN_CIPHER_ID`** の値を
   **`5b9c1065-e39d-4a43-a04a-e59bcea3e03f`** にハードコードする。
2. **Docker** でイメージをビルドし、
   リポジトリ **`registry.killer.sh:5000/sun-cipher`** に
   **`latest`** と **`v1-docker`** の 2 つのタグを付けてプッシュする。
3. **Podman** でも同じイメージをビルドし、
   タグ **`v1-podman`** を付けて同リポジトリにプッシュする。
4. **Podman** を使い、バックグラウンドで動くコンテナ **`sun-cipher`** を起動する。
   画像は **`registry.killer.sh:5000/sun-cipher:v1-podman`**。
   実行ユーザは **`candidate@ckad9043`** であり、**`root@ckad9043`** ではないこと。
5. そのコンテナ **`sun-cipher`** のログを **`/11/logs`** に書き出す。
   さらに、Podman で稼働中のコンテナ一覧を **`/11/containers`** に保存する。



====================================
dockerは後回し




====================================
Q12

Question 12:
Solve this question on instance: ssh ckad5601

1. **PersistentVolume を作成**

    名前空間はearth
   * 名前: **`earth-project-earthflower-pv`**
   * 容量: **2 Gi**
   * アクセスモード: **ReadWriteOnce**
   * `hostPath`: **`/Volumes/Data`**
   * **storageClassName は設定しない**

2. **PersistentVolumeClaim を作成（Namespace `earth`）**

   * 名前: **`earth-project-earthflower-pvc`**
   * リクエスト容量: **2 Gi**
   * アクセスモード: **ReadWriteOnce**
   * **storageClassName は設定しない**
   * 作成した PV と正しくバインドされていること

3. **Deployment を作成（Namespace `earth`）**

   * 名前: **`project-earthflower`**
   * Pod イメージ: **`httpd:2.4.41-alpine`**
   * 上記 PVC をマウントし、マウント先は **`/tmp/project-data`**

====================================

apiVersion: v1
kind: PersistentVolume
metadata:
  name: earth-project-earthflower-pv
spec:
  capacity:
    storage: 2Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain   
  storageClassName: ""
  hostPath:
    path: /Volumes/Data


apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: earth-project-earthflower-pvc
  namespace: earth
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 2Gi
  storageClassName: ""


apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: project-earthflower
  name: project-earthflower
  namespace: earth
spec:
  replicas: 1
  selector:
    matchLabels:
      app: project-earthflower
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: project-earthflower
    spec:
      containers:
      - image: httpd:2.4.41-alpine
        name: httpd
        resources: {}
        volumeMounts:
        - name: vol
          mountPath: /tmp/project-data
      volumes:
        - name: vol
          persistentVolumeClaim:
            claimName: earth-project-earthflower-pvc



====================================
Q13

Question 13:
Solve this question on instance: ssh ckad9043

Moonpie チーム（Namespace **`moon`**）で追加ストレージが必要になりました。
次の要件でリソースを作成してください。

1. **StorageClass `moon-retain`** を新規作成

   * `provisioner`: **`moon-retainer`**
   * `reclaimPolicy`: **`Retain`**

2. **PersistentVolumeClaim `moon-pvc-126`** を Namespace **`moon`** に作成

   * 要求容量: **3 Gi**
   * アクセスモード: **`ReadWriteOnce`**
   * 使用する StorageClass: **`moon-retain`**

> ※ `moon-retainer` プロビジョナーは別チームが後で用意するため、PVC はまだ **Bound** 状態にならない見込みです。

3. PVC のステータスに表示される **バインドできない理由メッセージ** を取得し、
   **`/13/pvc-126-reason`**（ckad9043 ノード）というファイルに書き込んでください。


kubectl apply -f q13.yaml

# q13.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: moon
====================================

q13-a.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: moon-retain
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: moon-retainer
reclaimPolicy: Retain 
allowVolumeExpansion: true
mountOptions:
  - discard # this might enable UNMAP / TRIM at the block storage layer
volumeBindingMode: WaitForFirstConsumer
parameters:
  guaranteedReadWriteLatency: "true" # provider-specific
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: moon-pvc-126
  namespace: moon
spec:
  resources:
    requests:
      storage:3G
  accessModes:
    - ReadWriteOnce
  storageClassName: "moon-retain"




====================================
Q15

Question 15:
Solve this question on instance: ssh ckad9043

Moonpie チーム（Namespace **`moon`**）には **`web-moon`** という nginx Deployment がありますが、設定が途中で止まっています。
仕上げとして、次の作業を行ってください。

1. **ConfigMap `configmap-web-moon-html`** を作成する

   * ファイル **`/15/web-moon.html`** の内容を
     `data` セクションの **キー名 `index.html`** に入れる

2. Deployment **`web-moon`** は、この ConfigMap を読み込んで HTML を配信するように設定済みです。

   * たとえば一時的な **`nginx:alpine`** Pod を立てて `curl` を実行し、
     ページが正しく返ることを確認してください。


kubectl apply -f q15.yaml

# q15.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-moon
  namespace: moon
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-moon
  template:
    metadata:
      labels:
        app: web-moon
    spec:
      containers:
        - name: nginx
          image: nginx:1.25-alpine        # 任意で固定
          ports:
            - containerPort: 80
          volumeMounts:
            - name: web-html
              mountPath: /usr/share/nginx/html
      volumes:
        - name: web-html
          configMap:                      # ★ まだ存在しない
            name: configmap-web-moon-html
            items:
              - key: index.html
                path: index.html


====================================




====================================
Q16

Question 16:
Solve this question on instance: ssh ckad7326

Mercury2D のテックリードは、たび重なる “データ欠落インシデント” に対処するため **ログを強化** することにしました。

* **Namespace `mercury`** にある Deployment **`cleaner`** には、
  **`cleaner-con`** というコンテナが既に存在し、ボリュームをマウントして
  **`cleaner.log`** というファイルにログを書き込んでいます。

* 現在の Deployment の YAML は **`q16.yaml`** にあります。
  変更を加えたら **`/16/cleaner-new.yaml`**（ckad7326 ノード）に保存し、
  Deployment が正常に動いていることを確認してください。

* **新たにサイドカーコンテナ `logger-con`** を追加してください。

  * イメージ: **`busybox:1.31.0`**
  * 先ほどと同じボリュームをマウント
  * `cleaner.log` の内容を **標準出力 (stdout)** に流す
    （例: `tail -f /var/log/cleaner/cleaner.log` など）
    こうすると `kubectl logs` でログを参照できるようになります。

* 最後に、新サイドカーのログを確認し、
  **データ欠落インシデントに関する手掛かりが出力されていないか** チェックしてください。


kubectl apply -f q16.yaml

# q16.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cleaner
  namespace: mercury
  labels:
    app: cleaner
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cleaner
  template:
    metadata:
      labels:
        app: cleaner
    spec:
      containers:
        # --- メイン処理コンテナ ----------------------------------
        - name: cleaner-con
          image: busybox:1.31.0   # 例
          command: ["sh", "-c", "while true; \
                     do echo \"$(date) - cleaning job ran\" \
                     >> /var/log/cleaner/cleaner.log; \
                     sleep 10; done"]
          volumeMounts:
            - name: logs-vol
              mountPath: /var/log/cleaner
      volumes:
        - name: logs-vol
          emptyDir: {}            # ログを 2 つのコンテナで共有予定

====================================




====================================
Q17

Question 17:
Solve this question on instance: ssh ckad5601

あなたは先日のランチで、Mars Inc 部門の同僚に **InitContainer の素晴らしさ** を熱弁しました。
同僚は実際に動くところを見たいそうです。

* 既存の Deployment の YAML が **`/17/test-init-container.yaml`** にあります。
  これはイメージ **`nginx:1.17.3-alpine`** で 1 つの Pod を立ち上げ、
  マウントされたボリュームからファイルを配信しますが、現在そのボリュームは空です。

**課題**

1. **InitContainer `init-con`** を追加してください。

   * イメージ: **`busybox:1.31.0`**
   * アプリ本体と同じボリュームをマウントし、
     ルート（マウント先）に **`index.html`** を作成し、内容は `"check this out!"` とする。
     （正しい HTML でなくても構いません）

2. 変更が反映されたら、たとえば一時的な **`nginx:alpine`** Pod から `curl` を実行し、
   `index.html` が返ってくることを確認してください。


kubectl apply -f q17.yaml

# q17.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-init
  namespace: mars
  labels:
    app: test-init
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-init
  template:
    metadata:
      labels:
        app: test-init
    spec:
      volumes:
        - name: content-vol
          emptyDir: {}
      containers:
        - name: nginx
          image: nginx:1.17.3-alpine
          ports:
            - containerPort: 80
          volumeMounts:
            - name: content-vol
              mountPath: /usr/share/nginx/html
====================================









====================================
Q19

Question 19:
Solve this question on instance: ssh ckad5601

Namespace **`jupiter`** には、レプリカ数 1 の Apache Deployment **`jupiter-crew-deploy`** と、それを公開する **ClusterIP Service `jupiter-crew-svc`** が存在します。
この Service を **NodePort** タイプに変更し、**ポート 30100** でクラスタ内のすべてのノードからアクセスできるようにしてください。

その後、各ノードの **内部 IP アドレス** と **ポート 30100** を使い、`curl` で NodePort Service をテストします（メイン端末からノード IP に直接アクセス可能）。

* **どのノードで Service に到達できましたか？**
* **Pod はどのノードで稼働していましたか？**


kubectl apply -f q19-01.yaml,q19-02.yaml,q19-03.yaml

# q19-01.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: jupiter

# q19-02.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jupiter-crew-deploy
  namespace: jupiter
  labels:
    app: jupiter-crew
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jupiter-crew
  template:
    metadata:
      labels:
        app: jupiter-crew
    spec:
      containers:
        - name: apache
          image: httpd:2.4-alpine
          ports:
            - containerPort: 80

# q19-03.yaml
apiVersion: v1
kind: Service
metadata:
  name: jupiter-crew-svc
  namespace: jupiter
spec:
  type: ClusterIP
  selector:
    app: jupiter-crew
  ports:
    - name: http
      port: 80
      targetPort: 80
      protocol: TCP
====================================




====================================
Q20

Question 20:
Solve this question on instance: ssh ckad7326

Namespace **`venus`** には **`api`** と **`frontend`** の 2 つの Deployment があり、どちらも Service でクラスター内に公開されています。

1. **NetworkPolicy `np1`** を作成し、Deployment **`frontend`** からの **外向き TCP 通信** を制限して、**Deployment `api` への通信だけを許可**してください。
2. DNS 解決用に **UDP/TCP ポート 53** への外向き通信は引き続き許可する必要があります。

動作確認:
`frontend` の Pod から次を実行してテストしてください。

* `wget www.google.com`
* `wget api:2222`


kubectl apply -f q20-01.yaml,q20-02.yaml,q20-03.yaml,q20-04.yaml

# q20-01.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: venus

# q20-02.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: venus
  labels:
    app: api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
        - name: api
          image: busybox:1.31.0            # wget が入っていて軽量
          command:
            - sh
            - -c
            - |
              # “HTTP/1.1 200 OK” を返す簡易サーバ
              echo '<h1>api OK</h1>' > /www/index.html
              httpd -f -p 2222 -h /www     # フォアグラウンドでポート 2222
          ports:
            - containerPort: 2222
              protocol: TCP

# q20-03.yaml
apiVersion: v1
kind: Service
metadata:
  name: api
  namespace: venus
spec:
  type: ClusterIP
  selector:
    app: api
  ports:
    - name: http
      port: 2222        # Service で解決されるポート
      targetPort: 2222  # Pod 側のポート
      protocol: TCP


====================================

====================================
Question 21:
Solve this question on instance: ssh ckad7326

Neptune チームでは、以下の要件で Deployment を作成してください。

* **Deployment 名**: `neptune-10ab`
* **Namespace**: `neptune`
* **Pod 数**: 3
* **コンテナ イメージ**: `httpd:2.4-alpine`
* **コンテナ名**: `neptune-pod-10ab`
* **リソース設定**:

  * メモリ要求 (requests): 20 Mi
  * メモリ制限 (limits): 50 Mi
* **ServiceAccount**: `neptune-sa-v2`（この ServiceAccount で Pod を実行すること）


kubectl apply -f q21.yaml

# q21.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: neptune
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: neptune-sa-v2
  namespace: neptune

====================================


====================================
Question 22:
Solve this question on instance: ssh ckad9043

Sun チーム（Namespace **`sun`**）では、特定の Pod を識別したいと考えています。

* 既に **`type: worker`** または **`type: runner`** というラベルを持つ **すべての Pod** に、
  **`protected: true`** という新しいラベルを追加してください。
* さらに、新ラベル **`protected: true`** が付いた Pod には、
  アノテーション **`protected: "do not delete this pod"`** も付与してください。

kubectl apply -f q22-01.yaml,q22-02.yaml

# q22-01.yaml
# neptune / sun それぞれの Namespace を作成
apiVersion: v1
kind: Namespace
metadata:
  name: neptune
---
apiVersion: v1
kind: Namespace
metadata:
  name: sun
---
# Neptune チーム用 ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: neptune-sa-v2
  namespace: neptune

# q22-02.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: neptune-10ab
  namespace: neptune
  labels:
    app: neptune-10ab
spec:
  replicas: 1            # ← ★ ここを 3 に直す
  selector:
    matchLabels:
      app: neptune-10ab
  template:
    metadata:
      labels:
        app: neptune-10ab
    spec:
      serviceAccountName: neptune-sa-v2
      containers:
        - name: neptune-pod-10ab     # ← ★ 課題どおり
          image: httpd:2.4-alpine    # ← ★ 課題どおり
          resources:
            requests:
              memory: "20Mi"         # ← ★ 課題どおり
            limits:
              memory: "50Mi"         # ← ★ 課題どおり

# q22-03.yaml
# worker 役
apiVersion: v1
kind: Pod
metadata:
  name: worker-a
  namespace: sun
  labels:
    type: worker
spec:
  containers:
    - name: pause
      image: registry.k8s.io/pause:3.9
---
apiVersion: v1
kind: Pod
metadata:
  name: worker-b
  namespace: sun
  labels:
    type: worker
spec:
  containers:
    - name: pause
      image: registry.k8s.io/pause:3.9
---
# runner 役
apiVersion: v1
kind: Pod
metadata:
  name: runner-a
  namespace: sun
  labels:
    type: runner
spec:
  containers:
    - name: pause
      image: registry.k8s.io/pause:3.9
---
# ラベルが条件に合わない Pod（動作確認用）
apiVersion: v1
kind: Pod
metadata:
  name: misc-x
  namespace: sun
  labels:
    type: misc
spec:
  containers:
    - name: pause
      image: registry.k8s.io/pause:3.9

