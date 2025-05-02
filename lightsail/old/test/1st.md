=========================================================
問題1
=========================================================
環境準備

次のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/1/resources.yaml

問題
selector名前空間では、pod-1からpod-10までの10個のPodが実行されています。それぞれのPodには、app: "Pod名"のラベルが付与されています。以下のラベルを持つPodのログを、/etc/pods.logに出力して下さい。

app: pod-3
app: pod-7
app: pod-8

---------------------------------------------------------
ログ出力とselect機能を試す問題
クベコントロール ログ を/etc/pods.logに出力 selectでappを指定する

kubectrl log (in  select=app ) /etc/pods.log
---------------------------------------------------------

・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
kubectrl logs -n filter -l 'app in (pod-3, pod-7, pod-8)' > /etc/pods.log

・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題2
=========================================================
環境準備

次のコマンドを実行して、問題に必要なリソースをデプロイして下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/2/resources.yaml



問題

credential名前空間で、login Deploymentが実行するコンテナは環境変数USERNAMEとPASSWORDをcreds Secretから参照しています。credsが保持しているPASSWORDの値をmy-new-passwordに変更して下さい。

---------------------------------------------------------
configMapとSecretを試す問題
クベコントロールでcredential名前空間を作成
configMapとSecretをlogin Deploymentに書き込む
環境変数 configMap USERNAME PASSWORD （Secretの名前はcreds Secretだが、configMapの名前は無いのか、なくても指定は出来そうな気はする）
秘匿データ secret  creds Secret USERNAME PASSWORD PASSWORD= my-new-password
---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
---
apiVersion: v1
kind: Namespace
metadata:
  name: credential
---
apiVersion: v1
data:
  PASSWORD: my-new-password
  USERNAME: bXktdXNlcgo=
kind: Secret
metadata:
  name: creds
  namespace: credential
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: login
  name: login
  namespace: credential
spec:
  replicas: 2
  selector:
    matchLabels:
      app: login
  template:
    metadata:
      labels:
        app: login
    spec:
      containers:
      - image: nginx:alpine
        name: login
        envFrom:
        - secretRef:
            name: creds

・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・

=========================================================
問題3
=========================================================
環境準備

1. wgetコマンドを使用して、以下のURLからファイルをダウンロードして下さい。

https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/3/updated_index.html



2. 次のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/3/resources.yaml



問題

web名前空間で実行されているmy-web Deploymentは、nginxイメージコンテナを実行するPodを管理しています。DeploymentはNodePortタイプのサービスで公開されており、curl controlplane:32100を実行してコンテナに接続できます。コンテナが表示するindex.htmlファイルを、updated_index.htmlに変更する必要があります。

index.htmlをキー、updated_index.htmlファイルをバリューとして保持するConfigMapを作成し、/usr/share/nginx/htmlディレクトリにマウントされているConfigMapを更新して下さい。ConfigMapの名前はnew-index-cmとします

---------------------------------------------------------
ConfigMap、サービス、Volumeがテーマ ConfigMapを更新が目標（しかし、肝心の詳細がわからず、、、）
web名前空間佐久市江
my-web Deployment YAML作成
イメージはnginx
volume作成 /usr/share/nginx/html
ConfigMapを設定 new-index-cm
サービス YAML作成

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・
---
apiVersion: v1
kind: Namespace
metadata:
  name: web
---
apiVersion: v1
data:
  index.html: |
    old
kind: ConfigMap
metadata:
  name: old-index-cm
  namespace: web
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: my-web
  name: my-web
  namespace: web
spec:
  replicas: 5
  selector:
    matchLabels:
      app: my-web
  template:
    metadata:
      labels:
        app: my-web
    spec:
      containers:
      - image: nginx
        name: nginx
        volumeMounts:
        - name: index
          mountPath: /usr/share/nginx/html
      volumes:
      - name: index
        configMap:
          name: new-index-cm
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: my-web
  name: my-svc
  namespace: web
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
    nodePort: 32100
  selector:
    app: my-web
  type: NodePort

・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・

=========================================================
問題4
=========================================================
環境準備

1. wgetコマンドを実行して、次のURLからfrontend.yamlファイルをダウンロードして下さい。

https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/4/frontend.yaml



2. wgetコマンドを実行して、次のURLからhaproxy.cfgファイルをダウンロードして下さい。

https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/4/haproxy.cfg



3. 次のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/4/resources.yaml



問題

ambassador名前空間で稼働しているfrontend Podは、ポート番号8080を使用して、５秒毎にapi-serviceに接続します。api-serviceのポート番号は、9090に変更する必要があります。以下のタスクを実行し、frontend Podが引き続きapi-serviceに接続できる様に、新しいコンテナを追加して下さい。



1. api-serviceの公開するポート番号を、9090番に変更して下さい



2. haproxy.cfgファイルを使用して、haproxy-cfgというConfigMapを作成して下さい。



3. frontend Podに、haproxy:alpineイメージを使用したコンテナを追加して下さい。コンテナ名はhaproxyとし、/usr/local/etc/haproxyディレクトリにhaproxy-cfg ConfigMapをマウントして下さい。なお、変更にはfrontend Podのマニフェストファイルであるfrontend.yamlを使用して下さい。



4. frontendコンテナからServiceへの接続が、新しいエンドポイントに正しくプロキシされる様に、接続先をapi-serviceからlocalhostに変更して下さい。

---------------------------------------------------------
1 サービスの設定を問う問題
デプロイではなく、サービスヤムルのポートを9090番に変更

2ConfigMapの設定を問う問題
frontend Pod YAｍｌに ConfigMap設定を追加

3 マルチPod(frontend.yamlにfrontend podとhaproxy podが同居 サイドカー？マルチポッド？そもそもデプロイメントはマルチイメージできないのだろうか)、イメージとボリューム設定
はhaproxy Pod YAMLのimageにhaproxy:alpine
volume /usr/local/etc/haproxy
4
---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・



=========================================================
問題5
=========================================================
環境準備

次のコマンドを実行して、問題に必要なリソースをデプロイして下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/5/resources.yaml



問題

service名前空間で実行されるpod-reader Deploymentは、5秒ごとに"kubectl get pods"コマンドを実行します。

現在、Deploymentのログにはエラーメッセージが出力されています。以下のタスクを実行し、エラーを修正して下さい。なお、解答に必要なリソースは全て作成されており、新しいリソースを作成する必要はありません。



1. pod-reader Deploymentのログを確認し、エラーメッセージを調査して下さい。



2. pod-reader Deploymentを修正し、エラーの原因となっている問題を解決して下さい。

---------------------------------------------------------
１ k8s ログ確認
kubectrl log pod-reader

２ RBAC問題
name: pod-readerがpod-reader-saが正しいのではそうじゃないとサービスアカウントとRoleBinding RBACが紐づかない
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・




=========================================================
問題6
=========================================================
環境準備

次のコマンドを実行して問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/6/resources.yaml



問題

network名前空間では、デフォルトでは全てのPodの内向き（ingress）トラフィックが無効化されています。web Podからapi Podへの内向きのトラフィックを許可するため、api-netpolというNetworkPolicyが作成されましたが、エラーが発生しています。web Podに必要な設定を追加し、api Podへの接続を有効化して下さい。

なお、解答に必要なKubernetesリソースは全て作成されており、新しく作成する必要はありません。また、既存のNetworkPolicyは変更または削除しないでください。

---------------------------------------------------------
そもそもbacがないのでwebでは？

    - podSelector:
        matchLabels:
          role: backend
---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題7
=========================================================
環境準備

次のコマンドを実行して問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/7/resources.yaml



問題

resource-management名前空間では、cpu-resource-constraintというLimitRangeによって、CPUリソース使用量の最大値が定義されています。

nginxイメージを使用してmanagedというPodを作成して下さい。なお、Podには以下の条件を満たすリソース管理を設定して下さい。



コンテナのCPUリソース要求として、200mを設定して下さい。

resource-management名前空間に設定された最大cpu制約の半分を、コンテナのリソース制限として設定して下さい。

---------------------------------------------------------
spec設定の知識がテーマ
resouce
spec{
    cpu:200m
    max-cpu:cpu-resource-constraint.LimitRange * 0.5
}
---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題8
=========================================================
問題

1. cronという名前空間を作成し、以下の条件を満たすCronJobを作成して下さい。

コンテナイメージはalpineを使用し、CronJobの名前はps-cronとします。ps-cronは"ps aux"コマンドを1分毎に実行し、成功したJobを5、失敗したJobを3まで保存します。また、Jobは開始から6秒経過したPodを終了させます。



2. CronJobからJobを作成して下さい。Job名はps-jobとします。

---------------------------------------------------------
Jobがテーマ
type CronJob
名前空間はcron
[sh： sleep 60s; ps aux;]

まったくわからない
成功したJobを5、失敗したJobを3まで保存します。また、Jobは開始から6秒経過したPodを終了させます。

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題9
=========================================================
環境準備

1. wgetコマンドを使用して、次のURLからyamlファイルをダウンロードして下さい。

https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/9/logger.yaml



2. 次のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/9/resources.yaml



問題

adapter名前空間において、loggerという名前のPodがbusyboxイメージを使用してコンテナを実行しています。このコンテナは、10秒ごとにdateコマンドの結果をJSON形式でinput.logファイルに記録します。PodはemptyDirボリュームを/tmp/logディレクトリにマウントし、input.logファイルをそこに保存します。



Podにfluent/fluentd:edgeイメージを使用したコンテナを追加し、/tmp/log/input.logの内容を/tmp/log/output/ディレクトリ内のbufferファイルに出力します。次の手順を実行して下さい。



コンテナ名をfluentdに設定して下さい

loggerコンテナと共有するボリュームを/tmp/logディレクトリにマウントして下さい。

/fluentd/etcディレクトリにfluentd-configmapをマウントして下さい。

---------------------------------------------------------
マルチポッド、ボリューム、コマンド、
共有ボリューム

fluentd podをlogger pod YAMLに追加しマルチポッド
fluentdにボリュームマウントする configMap fluentd-configmapで指定 /tmp/log
---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題10
=========================================================
問題

contextという名前空間を作成し、そこにsecure-redisというPodを作成して下さい。コンテナイメージには、redis:alpineを使用し、コンテナのSecurityContextには以下の項目を設定して下さい。



ユーザーID: 2000で実行する。

Privilege escalationをtrueとする。

NET_ADMIN capabilityを付与する。

---------------------------------------------------------
セキュアコンテキスト問題
context名前空間を作成
secure-redis pod YAML作成
イメージ redis:alpine

SecurityContextには以下の項目を設定と動作確認方法が全く記憶から消えている
一度コードリードはしている

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題11
=========================================================
環境準備

1. 次のコマンドを実行して、Ingress Controllerをインストールして下さい。

curl -s https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/11/init-ingress.sh | sh



2. 次のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/11/resources.yaml



問題

path-ingress名前空間では、menu-svcとcontact-svcというClusterIPタイプのServiceが、それぞれmenu-appとcontact-appというPodを公開しています。どちらのServiceも、ポート番号は80番を使用します。

contact-svcはinfo-ingressというIngressによってルーティングされ、http://path-ingress.info:31100/contactを使用してcontact-appにアクセスすることが出来ます。



info-ingressを変更し、http://path-ingress.info:31100/menuを使用してmenu-appにアクセスできる設定を追加して下さい。

---------------------------------------------------------
イングレス サービス マルチポッド ルーティングという事はselect match?

サービスで
pathをmenu
podをmenu-ap
に変更

    http:
      paths:
        - path: /menu
          pathType: Prefix
          backend:
            service:
              name: menu-svc
              port:
                number: 80
---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題12
=========================================================
環境準備

1. wgetコマンドを使用して、次のURLからyamlファイルをダウンロードして下さい。

https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/12/payment.yaml



2. 次のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/12/resources.yaml



問題

pay名前空間では、payment  Deploymentがpayment-svcというServiceにより、NodePort番号31120を使用して外部のネットワークに公開されています。

カナリアデプロイメント戦略を利用し、アプリケーションの新しいバージョンをリリースする必要があります。以下のタスクを実行し、新しいバージョンをDeploymentで作成されるレプリカの20％に展開して下さい。また、アプリケーションを実行するレプリカ数の合計は5に設定して下さい。



1. paymentと同じPodの構成で、payment-canary というDeploymentを作成して下さい。app-versionラベルの値には、canaryを設定して下さい。レプリカ数には、アプリケーションを実行する合計の20％を設定して下さい。

（payment.yamlは、payment Deploymentのマニフェストです。ファイルをコピーしてpayment-canary Deploymentの作成に使用して下さい。）



2. payment-svcを更新し、トラフィックの20％をpayment-canaryに送信して下さい。



なお、curl controlplane:31120を実行することでpayment-svcへの接続をテストする事が出来ます。

---------------------------------------------------------
カナリアデプロイメント自体を学習していない
一気に切り替えるのではなく、すこしデプロイしてOKならば全部切り替えるという方式と認識
---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題13
=========================================================
環境準備

以下のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/13/resources.yaml



問題

server名前空間で作成されているwebapp Podは、bitnami/expressイメージを使用するコンテナを実行しています。Podは同じ名前空間に作成されているwebsvc Serviceによって公開される必要があります。

現在、websvc Serviceを通じてwebapp Podに接続することができません。websvc Serviceの構成を確認し、問題の原因を修正してください。なお、変更はwebsvcにのみ適用し、webapp Podは変更しないで下さい。

---------------------------------------------------------
kind: Service
targetPort: 3000
3030が正しいのでは
---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題14
=========================================================
問題

1. rolling-updateという名前空間を作成し、rollingという名前のDeploymentを作成して下さい。イメージはredis:6.2-alpineを使用し、レプリカ数は5とします。strategyのtypeにはRollingUpdateを指定し、maxSurgeを20%、maxUnavailableを2に設定して下さい。



2. kubectl setコマンドを実行し、rollingDeploymentが実行するコンテナのイメージをredis:7.2-alpineに更新して下さい。



3. rollingDeploymentを一つ前のリビジョンにロールバックして下さい。

---------------------------------------------------------
ローリングアップデート自体未学習の為、スキップ
---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題15
=========================================================
環境準備

1. wgetコマンドを使用して、次のURLからyamlファイルをダウンロードして下さい。

https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/15/web.yaml



2. 以下のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/15/resources.yaml



問題

probes名前空間では、webという名前のPodが作成されています。web PodにHTTPリクエストによるLiveness ProbeとReadiness Probeを追加して下さい。詳細は以下のとおりです。



Liveness Probeでは、80番ポートを使用して/liveエンドポイントが正常なステータスコードを返すかどうかを認識します。最初のProbeを実行する前に5秒間待機し、その後、10秒おきに実行されます。

Readiness Probeでは、80番ポートを使用して/readyエンドポイントが正常なステータスコードを返すかどうかを認識します。最初のProbeを実行する前に15秒間待機し、その後、10秒おきに実行されます。



ダウンロードしたweb.yamlは、web Podのマニフェストファイルです。上記のLiveness ProbeとReadiness Probeをweb.yamlに追加し、実行中のPodに変更を適用して下さい。

---------------------------------------------------------
iveness ProbeとReadiness Probeがテーマ
kind: Podのスペックにiveness Probe /live 80 とReadiness Probe /ready 80  を追記するのでは

---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題16
=========================================================
問題

1. helmにbitnamiという名前のリポジトリを追加して下さい。リポジトリのURLはhttps://charts.bitnami.com/bitnamiを使用して下さい。



2. helm search repoコマンドを使用してbitnami/nginxチャートが存在することを確認して下さい。



3. helmを使用してckad-helm名前空間にbitnami/nginxチャートをインストールして下さい。リリース名はmy-nginxとします。



4. helm listコマンドを実行して、my-nginxがデプロイされていることを確認後、kubectl get deploy コマンドを実行して、レプリカの数を確認して下さい。



5. helm upgradeコマンドを実行して、my-nginxのレプリカ数を2に更新して下さい。

---------------------------------------------------------
helmはＣＫＡＤ対象外なので、スキップ
---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題17
=========================================================
環境準備

1. wgetコマンドを実行し、次のURLから問題に必要なyamlファイルをダウンロードして下さい。

https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/17/ckad-pv-claim.yaml



2. 以下のコマンドを実行し、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/17/resources.yaml



問題

persistent名前空間では、ckad-pv Persistent Volumeとckad-pv-claim Persistent Volume Claimが作成されています。ckad-pv は、ckad-pv-claim をバインドする必要があります。

ckad-pv-claimのSTATUSがPendingになっている原因を特定し、Boundになる様に修正して下さい。



なお、修正にはダウンロードしたckad-pv-claim.yamlファイルを使用し、ckad-pv は変更しないで下さい。

---------------------------------------------------------
Volume Claimがテーマ

storage: 100Miが正しいのでは

apiVersion: v1
kind: PersistentVolume
metadata:
  name: ckad-pv
  namespace: persistent
spec:
  capacity:
    storage: 500Mi
---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


=========================================================
問題18
=========================================================
環境準備

次のコマンドを実行して、問題に必要なリソースを作成して下さい。

kubectl apply -f https://raw.githubusercontent.com/nz-cloud-udemy/ckad-questions/main/practice-questions/18/resources.yaml



問題

session名前空間では、redis-deployという名前のDeploymentが作成されています。このDeploymentは、redis:alpineイメージを使用したコンテナをレプリカ数1で実行することを目的としていますが、現在エラーが発生しており、Podの起動に失敗しています。エラーの原因を特定し、問題を解決して下さい。

---------------------------------------------------------
- image: redis:alpineeの位置がまちがっているのでは、

template？
---------------------------------------------------------
・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・


・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・・

