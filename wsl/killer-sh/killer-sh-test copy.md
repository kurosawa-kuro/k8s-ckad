cd /home/wsl/dev/k8s-ckad/wsl/script
make reset-heavy
cd /home/wsl/dev/k8s-ckad/wsl/killer-sh

alias k=kubectl
export do="--dry-run=client -o yaml"
alias kn='kubectl config set-context --current --namespace '
alias kcfg='kubectl get cm,secret,sa,role,pvc,svc,events -n'

kubectl config set-context --current --help | grep -A3 -B3 -- --namespace

# c s s r p s e
====================================
Q1

The DevOps team would like to get the list of all Namespaces in the cluster.  
Get the list and save it to ~/dev/k8s-ckad/wsl/killer-sh/namespaces
====================================


k get ns -A > ~/dev/k8s-ckad/wsl/killer-sh/namespaces

====================================
Q2

Question 2:
Solve this question on instance: ssh ckad5601

Create a single Pod of image httpd:2.4.41-alpine in Namespace default.  
The Pod should be named pod1 and the container should be named pod1-container.

Your manager would like to run a command manually on occasion to output the status of that exact Pod.  
Please write whilea command that does this into /home/wsl/dev/k8s-ckad/wsl/killer-sh/pod1-status-command.sh on ckad5601. The command should use kubectl.

====================================





====================================
Q3

Question 3:
Solve this question on instance: ssh ckad7326

Team Neptune needs a Job template located at job.yaml.  
This Job should run image busybox:1.31.0 and execute sleep 2 && echo done.  
It should be in namespace neptune, run a total of 3 times and should execute 2 runs in parallel.

Start the Job and check its history. Each pod created by the Job should have the label id: awesome-job.  
The job should be named neb-new-job and the container neb-new-job-container.

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

Team Mercury asked you to perform some operations using Helm, all in Namespace mercury:

1. Delete release internal-issue-report-apiv1  
2. Upgrade release internal-issue-report-apiv2 to any newer version of chart bitnami/nginx available  
3. Install a new release internal-issue-report-apache of chart bitnami/apache.  
   The Deployment should have two replicas—set these via Helm-values during install  
4. There seems to be a broken release, stuck in pending-install state. Find it and delete it

kubectl apply -f q4.yaml

# q4.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: mercury
====================================

====================================
Q5

Question 5:
Solve this question on instance: ssh ckad7326

Team Neptune has its own ServiceAccount named neptune-sa-v2 in Namespace neptune.  
A coworker needs the token from the Secret that belongs to that ServiceAccount.  
Write the base64 decoded token to file /opt/course/5/token on ckad7326.

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
Q6

Question 6:
Solve this question on instance: ssh ckad5601

Create a single Pod named pod6 in Namespace default of image busybox:1.31.0.  
The Pod should have a readiness-probe executing `cat /tmp/ready`. It should initially wait 5 seconds and then probe every 10 seconds. This will set the container ready only if the file `/tmp/ready` exists.

The Pod should run the command `touch /tmp/ready && sleep 1d`, which will create the necessary file to become ready and then idle. Create the Pod and confirm it starts.

====================================



====================================
Q7

Question 7:
Solve this question on instance: ssh ckad7326

The board of Team Neptune decided to take over control of one e-commerce webserver from Team Saturn. The administrator who once set up this webserver is no longer part of the organization. All information you could get was that the e-commerce system is called my-happy-shop.

Search for the correct Pod in Namespace saturn and move it to Namespace neptune. It doesn’t matter if you shut it down and spin it up again; it probably hasn’t any customers anyways.

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
Q8

Question 8:
Solve this question on instance: ssh ckad7326

There is an existing Deployment named api-new-c32 in Namespace neptune. A developer made an update to the Deployment but the updated version never came online. Check the Deployment’s revision history, find a revision that works, then rollback to it. Could you tell Team Neptune what the error was so it doesn’t happen again?

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
Q9

Question 9:
Solve this question on instance: ssh ckad9043

In Namespace pluto there is a single Pod named holy-api. It has been working okay for a while now but Team Pluto needs it to be more reliable.

Convert the Pod into a Deployment named holy-api with 3 replicas and delete the original Pod once done. The raw Pod template file is available at /opt/course/9/holy-api-pod.yaml.

In addition, the new Deployment should set `allowPrivilegeEscalation: false` and `privileged: false` in the container’s securityContext.  
Please create the Deployment and save its YAML under /opt/course/9/holy-api-deployment.yaml.

kubectl apply -f q9-01.yaml,q9-02.yaml,q20-03.yaml

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
Q10

Question 10:
Solve this question on instance: ssh ckad9043

Team Pluto needs a new cluster internal Service.  
Create a ClusterIP Service named project-plt-6cc-svc in Namespace pluto.  
This Service should expose a single Pod named project-plt-6cc-api of image nginx:1.17.3-alpine—create that Pod as well.  
The Pod should be identified by label project: plt-6cc-api.  
The Service should use tcp port redirection of 3333:80.

Finally, use—for example—curl from a temporary nginx:alpine Pod to get the response from the Service.  
Write the response into /opt/course/10/service_test.html on ckad9043.  
Also check if the logs of Pod project-plt-6cc-api show the request and write those into /opt/course/10/service_test.log on ckad9043.
====================================



====================================
Q11

Question 11:
Solve this question on instance: ssh ckad9043

During the last monthly meeting you mentioned your strong expertise in container technology.  
Now the Build&Release team of department Sun is in need of your insight knowledge.  
There are files to build a container image located at /opt/course/11/image.  
The container will run a Golang application which outputs information to stdout.  
You're asked to perform the following tasks:

NOTE: Make sure to run all commands as user candidate; for docker use sudo docker

1. Change the Dockerfile. The value of the environment variable SUN_CIPHER_ID should be set to the hardcoded value 5b9c1065-e39d-4a43-a04a-e59bcea3e03f  
2. Build the image using Docker, named registry.killer.sh:5000/sun-cipher, tagged as latest and v1-docker; push these to the registry  
3. Build the image using Podman, named registry.killer.sh:5000/sun-cipher, tagged as v1-podman; push it to the registry  
4. Run a container using Podman, which keeps running in the background, named sun-cipher using image registry.killer.sh:5000/sun-cipher:v1-podman.  
   Run the container from candidate@ckad9043 and not root@ckad9043  
5. Write the logs your container sun-cipher produced into /opt/course/11/logs.  
   Then write a list of all running Podman containers into /opt/course/11/containers on ckad9043.


====================================
dockerは後回し




====================================
Q12

Question 12:
Solve this question on instance: ssh ckad5601

Create a new PersistentVolume named earth-project-earthflower-pv.  
It should have a capacity of 2Gi, accessMode ReadWriteOnce, hostPath /Volumes/Data and no storageClassName defined.

Next, create a new PersistentVolumeClaim in Namespace earth named earth-project-earthflower-pvc.  
It should request 2Gi storage, accessMode ReadWriteOnce and should not define a storageClassName.  
The PVC should be bound to the PV correctly.

Finally, create a new Deployment project-earthflower in Namespace earth which mounts that volume at /tmp/project-data.  
The Pods of that Deployment should be of image httpd:2.4.41-alpine.
====================================





====================================
Q13

Question 13:
Solve this question on instance: ssh ckad9043

Team Moonpie, which has the Namespace moon, needs more storage.  
Create a new PersistentVolumeClaim named moon-pvc-126 in that namespace.  
This claim should use a new StorageClass moon-retain with the provisioner set to moon-retainer and the reclaimPolicy set to Retain.  
The claim should request storage of 3Gi, an accessMode of ReadWriteOnce and should use the new StorageClass.

The provisioner moon-retainer will be created by another team, so it's expected that the PVC will not bind yet.  
Confirm this by writing the log message from the PVC into file /opt/course/13/pvc-126-reason.

kubectl apply -f q13.yaml

# q13.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: moon
====================================



====================================
Q14

Question 14:
Solve this question on instance: ssh ckad9043

You need to make changes on an existing Pod in Namespace moon called secret-handler.  
Create a new Secret secret1 which contains user=test and pass=pwd.  
The Secret’s content should be available in Pod secret-handler as environment variables SECRET1_USER and SECRET1_PASS.  
The YAML for Pod secret-handler is available at /opt/course/14/secret-handler.yaml.

There is existing YAML for another Secret at /opt/course/14/secret2.yaml; create this Secret and mount it inside the same Pod at /tmp/secret2.  
Your changes should be saved under /opt/course/14/secret-handler-new.yaml on ckad9043.  
Both Secrets should only be available in Namespace moon.

kubectl apply -f q14-01.yaml,q14-02.yaml

# q14-01.yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret1
  namespace: moon
type: Opaque            # ← 文字列そのまま扱えるよう stringData を使用
stringData:
  user: test
  pass: pwd

# q14-02.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-handler
  namespace: moon
  labels:                # (元のラベルがあればそのまま)
    app: secret-handler
spec:
  containers:
  - name: secret-handler
    image: # ... 元の image ...
    # ... (command / args / ports など既存定義) ...
    env:
      - name: SECRET1_USER
        valueFrom:
          secretKeyRef:
            name: secret1
            key: user
      - name: SECRET1_PASS
        valueFrom:
          secretKeyRef:
            name: secret1
            key: pass
    volumeMounts:
      - name: secret2-vol
        mountPath: /tmp/secret2
        readOnly: true
      # ... 既存 volumeMount があればここに残す ...
  volumes:
    - name: secret2-vol
      secret:
        secretName: secret2
        defaultMode: 0440
    # ... 既存 volumes があればここに残す ...
====================================






====================================
Q15

Question 15:
Solve this question on instance: ssh ckad9043

Team Moonpie has an nginx server Deployment called web-moon in Namespace moon.  
Someone started configuring it but it was never completed.  
To complete, please create a ConfigMap called configmap-web-moon-html containing the content of file /opt/course/15/web-moon.html under the data key-name index.html.

The Deployment web-moon is already configured to work with this ConfigMap and serve its content.  
Test the nginx configuration, for example using curl from a temporary nginx:alpine Pod.

kubectl apply -f q15.yaml

# q15.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-web-moon-html
  namespace: moon
data:
  index.html: |
    <!-- ここに /opt/course/15/web-moon.html の内容を貼り付ける -->

====================================




====================================
Q16

Question 16:
Solve this question on instance: ssh ckad7326

The Tech Lead of Mercury2D decided it’s time for more logging, to finally fight all these missing data incidents.  
There is an existing container named cleaner-con in Deployment cleaner in Namespace mercury.  
This container mounts a volume and writes logs into a file called cleaner.log.

The YAML for the existing Deployment is available at /opt/course/16/cleaner.yaml.  
Persist your changes at /opt/course/16/cleaner-new.yaml on ckad7326 but also make sure the Deployment is running.

Create a sidecar container named logger-con, image busybox:1.31.0, which mounts the same volume and writes the content of cleaner.log to stdout (you can use tail -f for this).  
This way it can be picked up by kubectl logs.  
Check if the logs of the new container reveal something about the missing data incidents.

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
        image: busybox:1.31.0        # 既存イメージが不明な場合のサンプル
        command: ["sh", "-c", "while true; do echo \"$(date) - cleaning job ran\" >> /var/log/cleaner/cleaner.log; sleep 10; done"]
        volumeMounts:
        - name: logs-vol
          mountPath: /var/log/cleaner
      # --- 追加するサイドカー ----------------------------------
      - name: logger-con
        image: busybox:1.31.0
        command: ["sh", "-c", "tail -F /var/log/cleaner/cleaner.log"]
        volumeMounts:
        - name: logs-vol
          mountPath: /var/log/cleaner
      # --------------------------------------------------------
      volumes:
      - name: logs-vol
        emptyDir: {}                 # ログ保存用に両コンテナが共有
====================================




====================================
Q17

Question 17:
Solve this question on instance: ssh ckad5601

Last lunch you told your coworker from department Mars Inc how amazing InitContainers are.  
Now he would like to see one in action.  
There is a Deployment YAML at /opt/course/17/test-init-container.yaml.  
This Deployment spins up a single Pod of image nginx:1.17.3-alpine and serves files from a mounted volume, which is empty right now.

Create an InitContainer named init-con which also mounts that volume and creates a file index.html with content "check this out!" in the root of the mounted volume.  
For this test we ignore that it doesn't contain valid HTML.

The InitContainer should be using image busybox:1.31.0.  
Test your implementation, for example using curl from a temporary nginx:alpine Pod.

kubectl apply -f q17.yaml

# q17.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-init
  namespace: mars          # 好きな Namespace があれば変更してください
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
        - name: content-vol      # ★ nginx と InitContainer で共有するボリューム
          emptyDir: {}
      # ---- これから追加する InitContainer 用のスペース -----------------
      # initContainers:
      #   - name: init-con
      #     image: busybox:1.31.0
      #     command: ["sh", "-c", "echo 'check this out!' > /usr/share/nginx/html/index.html"]
      #     volumeMounts:
      #       - name: content-vol
      #         mountPath: /usr/share/nginx/html
      # ------------------------------------------------------------------
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
Q18

Question 18:
Solve this question on instance: ssh ckad5601

There seems to be an issue in Namespace mars where the ClusterIP service manager-api-svc should make the Pods of Deployment manager-api-deployment available inside the cluster.

You can test this with curl manager-api-svc.mars:4444 from a temporary nginx:alpine Pod.  
Check for the misconfiguration and apply a fix.

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
Q19

Question 19:
Solve this question on instance: ssh ckad5601

In Namespace jupiter you'll find an apache Deployment (with one replica) named jupiter-crew-deploy and a ClusterIP Service called jupiter-crew-svc which exposes it.  
Change this Service to a NodePort one to make it available on all nodes on port 30100.

Test the NodePort Service using the internal IP of all available nodes and the port 30100 using curl; you can reach the internal node IPs directly from your main terminal.  
On which nodes is the Service reachable? On which node is the Pod running?

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
  type: ClusterIP          # ← ここを NodePort に直し、nodePort: 30100 を追加する
  selector:
    app: jupiter-crew
  ports:
    - name: http
      port: 80            # サービスが公開するポート
      targetPort: 80      # Pod 側のポート
      protocol: TCP
====================================




====================================
Q20

Question 20:
Solve this question on instance: ssh ckad7326

In Namespace venus you'll find two Deployments named api and frontend.  
Both Deployments are exposed inside the cluster using Services.  
Create a NetworkPolicy named np1 which restricts outgoing TCP connections from Deployment frontend and only allows those going to Deployment api.  
Make sure the NetworkPolicy still allows outgoing traffic on UDP/TCP port 53 for DNS resolution.

Test using: wget www.google.com and wget api:2222 from a Pod of Deployment frontend.

kubectl apply -f q20-01.yaml,q20-02.yaml,q20-03.yaml

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

Team Neptune needs 3 Pods of image httpd:2.4-alpine; create a Deployment named neptune-10ab for this.  
The containers should be named neptune-pod-10ab.  
Each container should have a memory request of 20Mi and a memory limit of 50Mi.

Team Neptune has its own ServiceAccount neptune-sa-v2 under which the Pods should run.  
The Deployment should be in Namespace neptune.

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

Team Sunny needs to identify some of their Pods in namespace sun.  
They ask you to add a new label protected: true to all Pods with an existing label type: worker or type: runner.  
Also add an annotation protected: "do not delete this pod" to all Pods having the new label protected: true.

kubectl apply -f q22-01.yaml,q22-02.yaml,q22-03.yaml

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

