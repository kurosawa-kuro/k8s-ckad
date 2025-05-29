承知しました。CKAD 試験対策向けの NetworkPolicy 学習ドキュメント全体を、公式 Kubernetes ドキュメントに準拠した信頼性の高い Markdown にリファクタリングします。

Deployment の統一や DNS egress 例など、CKAD 試験頻出ポイントを強調しつつ、公式の YAML スニペットに基づいて整理・修正いたします。完了次第お知らせいたします。

# Kubernetes NetworkPolicy 解説 (CKAD試験対策)

## NetworkPolicyの概要

**NetworkPolicy**はKubernetesにおけるPod間やPodと外部との通信をL3/L4レベル(IPアドレスやポート)で制御するためのリソースです。クラスタ内の通信に対する**ファイアウォール**のような役割を果たし、アプリケーション開発者の視点で「どのPodがどの通信を許可するか」を宣言的に指定できます。NetworkPolicyを利用するには、**対応するネットワークプラグイン(CNI)**のサポートが必要です。もしクラスターでNetworkPolicyを実装するプラグイン（例: Calico, Cilium など）を使用していなければ、NetworkPolicyリソースを作成しても**何の効果もありません**。

Kubernetesクラスターでは**デフォルトでPod間の通信は全て許可**されています。すなわち、NetworkPolicyによる制限を設けない状態では、Podは**非分離 (non-isolated)** 状態であり、あらゆる通信を受け付けます。NetworkPolicyを一つでも適用すると対象Podは**分離 (isolated)** 状態となり、そのポリシーで明示的に許可された通信以外は拒否されるようになります。ただし重要なのは、NetworkPolicyは**Podごとに適用**されるという点です。あるPodがNetworkPolicyの`podSelector`で選択されない限り、そのPodは引き続き全トラフィックを許可する非分離のままです。したがって、名前空間内で特定のPodにだけポリシーを適用しても、**他のPodには影響しません**（他のPodは依然として制限なく通信可能）。名前空間全体を網羅的に制限したい場合は、全Podを選択するポリシー（後述のデフォルト拒否ポリシー）を追加する必要があります。

NetworkPolicyには**Ingress（受信）**と**Egress（送信）**の2種類の通信方向を制御できます。ポリシーの適用対象となるPod（**対象Pod**）は`spec.podSelector`で選択し、許可するIngress元やEgress先の条件を`ingress.from`や`egress.to`で指定します。また、許可するポートやプロトコルを`ports`で指定できます。各ルールでは**指定した「送信元/送信先」と「ポート」の両方**にマッチする通信だけが許可されます。`ports`セクションを省略した場合は**全てのポート**を許可し、`from`/`to`セクションを省略した場合は**全ての送信元/送信先**を許可することを意味します（例: `ingress: - {}` と記述すると全ての通信元から全ポートを許可）。

NetworkPolicyリソースの`policyTypes`フィールドでIngress/Egressのどちらを制御するポリシーかを指定します。明示しない場合、デフォルトでIngressが適用され、さらに`egress`ルールを含む場合は自動的にEgressにも適用されます。各NetworkPolicyは**許可ルールの追加**のみを行い、暗黙的にその他の通信を拒否するモデルになっています。したがって**明示的な拒否ルールは存在しません**。複数のNetworkPolicyが同一のPodに適用される場合、それらのポリシーで許可された通信の**和集合**のみが通許されます（ポリシー同士が競合・優先されることはなく、すべて**加算的**に適用されます）。

**Ingress**ポリシーは対象Podへの外部からの流入トラフィックを制御し、**Egress**ポリシーは対象Podから外部への流出トラフィックを制御します。例えばIngressでは「どのPod（またはIPブロック、名前空間）から対象Podへの通信を許可するか」、Egressでは「対象Podからどの宛先（Pod、IP、名前空間）への通信を許可するか」を指定します。また、NetworkPolicyは**名前空間（Namespace）スコープ**のリソースです。基本的に**同じ名前空間内**のPod同士を`podSelector`で選択して許可できますが、別の名前空間のPodを許可対象に含めたい場合は`namespaceSelector`を用いて名前空間を指定します。**名前空間そのものは名前で直接指定できない**ため、あらかじめ対象のNamespaceにラベルを付与し、そのラベルで`namespaceSelector`をマッチさせる方法を取ります（Kubernetes v1.21以降では各Namespaceに自動で`kubernetes.io/metadata.name: <namespace名>`というラベルが付与されているため、それを用いて名前指定することも可能です）。

以下、CKAD試験の観点で特に重要となる**デフォルト拒否 (Default Deny)**、Ingress/Egressポリシーの具体例、`namespaceSelector`の活用方法、そして**DNS通信の扱い**について、順を追って解説します。

## 検証用リソースの作成

まずNetworkPolicyの効果を確認するためのサンプルリソースを用意します。ここでは例として**バックエンド**と**フロントエンド**に相当する2つのDeploymentをデフォルトの名前空間に作成し、バックエンドに対してフロントエンドからHTTP通信を行うシナリオを考えます。

- **バックエンド**: nginxを使用し、80番ポートでHTTPサーバーとして動作させます。Deployment名は “backend” とし、Serviceを作成して名前解決できるようにします。
    
    ```bash
    kubectl create deployment backend --image=nginx
    kubectl expose deployment backend --port=80 --target-port=80 --name=backend
    ```
    
- **フロントエンド**: 通信テスト用にcurlを利用できるコンテナを用意します。こちらはDeployment名を “frontend” とします（Pod内で必要に応じて`curl`や`wget`をインストールして使用します）。例えば小さなイメージとしてalpineベースのcurlコンテナを使い、Podが終了しないようスリープ状態にしておきます。
    
    ```bash
    kubectl create deployment frontend --image=alpine/curl -- sleep 3600
    ```

kubectl exec deploy/frontend -- curl -s http://backend.default.svc.cluster.local

    ※環境によって上記コマンドでうまく動作しない場合は、`kubectl create deployment frontend --image=alpine:latest`で作成後に手動でコンテナ内にcurlをインストールするか、別途`kubectl run`で`--command -- sleep`を指定してください。
    

上記により、デフォルトではfrontend PodからbackendのService (`backend.default.svc.cluster.local` またはPod IP) へのHTTP通信が問題なく成功するはずです。実際に`kubectl exec`でfrontendコンテナに入り、HTTPリクエストを送ってみると、レスポンスが返ってくることが確認できます（NetworkPolicy未適用時は全通信許可のため）。

## デフォルト拒否 (Default Deny) ポリシー

**「デフォルト拒否」**とは、特定の名前空間内のPodに対し**何も許可しないNetworkPolicy**を適用することで、**全てのIngressまたはEgressトラフィックをデフォルトで遮断**する設定です。Kubernetesでは名前空間にポリシーが一つも存在しない場合、その名前空間内のPodはIngressもEgressも全て許可されています。このデフォルト動作を変更し、セキュアな初期状態（ホワイトリスト方式）にするには、明示的に「全て拒否」のNetworkPolicyを作成します。

**Ingressのデフォルト拒否**を実装するNetworkPolicyは以下の通りです。`podSelector: {}`により名前空間内の**全てのPod**を選択し、`policyTypes: Ingress`を指定することでIngress方向のポリシーであることを示しています。ルール (`ingress`セクション) を一切指定しないため、このポリシーが適用されたPodには**あらゆるIngress通信が許可されなくなります**。

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: default
spec:
  podSelector: {}                 # この名前空間内の全Podを対象
  policyTypes:
  - Ingress                       # Ingress（受信）トラフィックに適用
  # ingressルールを指定しない（全て拒否）
```

この`default-deny-ingress`ポリシーをデプロイすると、**たとえ他のNetworkPolicyで選択されていないPodであっても**Ingressトラフィックが遮断されることが保証されます。つまり、同じ名前空間内の**全Podが外部からアクセスできない**状態になります。なお、このポリシーはIngressのみを制御し、Egressの動作は変更しません。

**Egressのデフォルト拒否**ポリシーもIngress版とほぼ同様で、`policyTypes: Egress`を指定し`egress`ルールを空にするだけです。全Podからの外向き通信を遮断するNetworkPolicyの例を示します。

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
  namespace: default
spec:
  podSelector: {}                 # この名前空間内の全Podを対象
  policyTypes:
  - Egress                        # Egress（送信）トラフィックに適用
  # egressルールを指定しない（全て拒否）
```

上記を適用すると、その名前空間内で**どのPodも外部への通信ができない**ことを保証できます（Ingressのデフォルト動作は変更しません）。

> **補足:** IngressとEgressの両方をデフォルト拒否にしたい場合、`policyTypes: [Ingress, Egress]`として`ingress`も`egress`もルールなしにした単一のNetworkPolicyで**全方向のデフォルト拒否**ポリシーを実現できます。NetworkPolicyはデフォルトdeny・許可ルールのみのモデルであり、explicit denyの機能は存在しない点に注意してください。

## Ingressルールの設定例 ～特定のPodからのアクセスのみ許可～

それでは、具体的なIngress制御の例として「**バックエンド（backend）への通信はフロントエンド（frontend）からのものだけ許可し、それ以外は拒否**」というポリシーを実現してみます。これはCKAD試験でも典型的なシナリオであり、例えば「ラベル`app=backend`を持つPodには、同じ名前空間内のラベル`app=frontend`を持つPodからのアクセス（TCP 80番のみ）だけを許可せよ」という問題設定に対応できます。

前提として、先ほど作成したbackendとfrontendは現在デフォルトでは全面通信許可の状態です。まず、Ingressをロックダウンするために**デフォルト拒否ポリシー**（前述の`default-deny-ingress`）を適用するところから始めます。

1. **デフォルト拒否ポリシーの適用**: 名前空間`default`に対し`default-deny-ingress`を適用します（既に適用済みであればこの手順は不要です）。これによりbackendを含む全てのPodはIngress非許可の状態になり、現時点ではfrontendからbackendへの通信も**できなくなる**はずです。例えばfrontend Pod内から`curl backend`等でアクセスしても応答がない（接続がタイムアウトする）状態になります。
    
2. **特定Ingress許可ポリシーの作成**: 次に、backendへのIngressを一部解放するNetworkPolicyを作成します。以下のマニフェストは、`app=backend`ラベルを持つPod（backend DeploymentのPod）を対象に、同じ名前空間内の`app=frontend`ラベルを持つPodからのTCP 80番ポート通信を許可するポリシーです。
    
    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: allow-frontend-ingress
      namespace: default
    spec:
      podSelector:
        matchLabels:
          app: backend            # 対象: backend Pod（app=backend）
      policyTypes:
      - Ingress
      ingress:
      - from:
        - podSelector:
            matchLabels:
              app: frontend       # 許可する送信元: app=frontendを持つPod（同一Namespace）
        ports:
        - protocol: TCP
          port: 80               # 許可するポート: TCP 80番
    ```
    
    このポリシーの意味するところは、「`app=backend`のPodには、**同じdefault名前空間内**の`app=frontend`のPodから来るTCP/80だけをIngress許可する」になります。なお`policyTypes`はIngressのみ指定しています。これを適用することで、デフォルト拒否下でもfrontendからbackendへのHTTPリクエスト**だけ**が例外的に通るようになります。他のPod（ラベル`app=frontend`を持たないPod）からbackendへのアクセスは引き続き拒否されます。
    
3. **動作確認**: ポリシー適用後、frontend Podからbackend Service（またはPod）へのHTTP通信を再度試みてください。`curl http://backend`などと実行すると、今度は**正常にレスポンスが返る**はずです。仮に別のPod（例: ラベル`app=frontend`を持たないPod）からbackendにアクセスしても、NetworkPolicyにより拒否され接続できないことを確認できます。
    

上記のように、**デフォルト拒否 + 必要なIngressを許可するポリシー**を組み合わせることで、安全なIngress制御を実現できます。NetworkPolicyによって一度Podをisolated状態にした上で、特定の条件だけホワイトリスト的に開放するのが基本的な設計方針となります。なお、Ingress方向のみ制限したため、backendからのEgressやfrontendからのEgressはこの時点ではまだ自由に行えます。

> **ワンポイント:** NetworkPolicyを作成した後は、`kubectl describe netpol <ポリシー名>`で内容を確認すると分かりやすいです。たとえば上記`allow-frontend-ingress`を適用後に`kubectl describe netpol allow-frontend-ingress -n default`を実行すると、「PodSelector: app=backend」「Allowing ingress traffic: from podSelector=app=frontend, port 80/TCP」といった要約が表示され、Kubernetesがポリシーをどう解釈しているか確認できます。

## Egressルールの設定例 ～外部へのアクセス制限とDNS～

次に、**Egress（外向き通信）の制限**について例を挙げます。シナリオとして、「**フロントエンド（frontend）から外部への通信は特定ポートのみ許可し、それ以外のポートは遮断**する。ただしDNSクエリは許可して名前解決できるようにする」ケースを考えます。これは例えば「アプリケーションが外部のサービスと通信するが、必要なポート（80番など）以外は禁止し、DNS解決ができなくならないようにする」という要件に対応します。

上記Ingressの例に続けて実施する場合、frontend Podは依然として非分離（全通信許可）の状態なので、まずはEgress側もポリシーで制限を加えます。

1. **特定Egress許可ポリシーの作成**: frontendからの外向き通信を絞り込むNetworkPolicyを作成します。以下のマニフェストは、`app=frontend`ラベルを持つPod（frontend DeploymentのPod）を対象に、**80番ポートのTCP通信のみ**を許可するEgressポリシーです（宛先IPやPodの指定が無いため、ポート80への通信であれば宛先は問わず許可されます）。
    
    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: allow-http-egress
      namespace: default
    spec:
      podSelector:
        matchLabels:
          app: frontend           # 対象: frontend Pod（app=frontend）
      policyTypes:
      - Egress
      egress:
      - ports:
        - protocol: TCP
          port: 80               # 許可する宛先ポート: TCP 80番 (HTTP)
        # 宛先(to)を指定しない -> 全ての宛先が対象
    ```
    
    これにより、frontend PodからのEgress通信は**TCP 80番ポート宛てのみ許可**され、それ以外（例えばTCP 443や他ポートへの通信）は禁止されます。たとえば、frontend Pod内からHTTPサーバー（ポート80）に対しては社内外問わず接続できますが、HTTPS(443)には接続できなくなります。
    
2. **動作確認（DNS問題の発生）**: `allow-http-egress`適用後、実際に挙動を確認します。frontend PodからbackendサービスのIPに向けてHTTPリクエストを送ると、ポート80通信のため**成功**します（HTTP 200 応答）。しかし、**ドメイン名での通信**に注意が必要です。例えばfrontendから`curl backend`（Service名でアクセス）や外部の`curl example.com`を実行すると、**名前解決ができず失敗**します。これは、ドメイン名を解決するDNSクエリ（UDP/TCP 53番）が許可されていないためです。Egressポリシーによりfrontend PodからDNSサーバ（CoreDNS）への通信もブロックされ、ホスト名がIPに引けなくなっているのです。
    
    この状態ではエラーメッセージとして「`Could not resolve host`」が出力されたり、タイムアウトが発生したりします。実際上、**外部やサービスにFQDNでアクセスするためにはDNSへの問い合わせを許可するルールが別途必要**になります。
    
3. **DNSクエリ許可ポリシーの追加**: frontend Podが正常に名前解決を行えるよう、DNS用のEgressルールを追加します。Cluster DNS（通常はkube-system名前空間のCoreDNS）が53番ポートで動作しているため、それに対する通信を許可するNetworkPolicyを作成します。
    
    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: allow-dns-egress
      namespace: default
    spec:
      podSelector:
        matchLabels:
          app: frontend           # 対象: frontend Pod
      policyTypes:
      - Egress
      egress:
      - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system   # kube-system名前空間
          podSelector:
            matchLabels:
              k8s-app: kube-dns       # CoreDNS（kube-dns）Pod
        ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
    ```
    
    上記ポリシーは「**kube-system名前空間**かつ**ラベル`k8s-app=kube-dns`を持つPod**（つまりDNSサーバのCoreDNS Pod）に対する53番ポート通信（UDP/TCP両方）を許可」することを意味しています。`namespaceSelector`と`podSelector`を組み合わせて特定Namespace内の特定Podを指定する書式に注意してください。Kubernetes v1.21+であればここでは`kubernetes.io/metadata.name: kube-system`という自動ラベルを利用していますが、互換性のためにkube-system Namespaceに手動でラベルを付与し、同様に指定しても構いません。
    
4. **動作確認（名前解決の成功）**: DNS許可ポリシー適用後、frontend Podから再度ドメイン名で通信を試みます。まずbackendサービスに対しホスト名（例: `backend` または `backend.default.svc.cluster.local`）でアクセスすると、今度は**正常に応答が返る**ことを確認できます。さらに、クラスタ外のドメイン（例えば`google.com`や`example.com`）に対してもHTTPリクエストを送ってみると、リダイレクトや200 OKが返ってきて**外部通信が成功する**ことがわかります。このように、DNSクエリ用ポリシーを追加することで、Egress制限下でも名前解決を伴う通信が可能になります。
    

> **補足:** 今回の`allow-http-egress`ポリシーでは宛先を制限せずポートのみ許可しましたが、NetworkPolicyでは`ipBlock`を使用して許可する**IPレンジ**を指定することもできます。たとえば`ipBlock: { cidr: 0.0.0.0/0, except: [...] }`のように記述すれば特定のCIDRブロック宛てのみ許可/拒否といった細かい制御も可能です（ただしFQDNによる制御はできず、IPアドレスベースになります）。CKADではIPブロックを用いた外部アクセス制限の指定が問われる場合もあるため、必要に応じて確認しておきましょう。

## Namespaceセレクターの活用 (他Namespaceとの通信)

上記の例ではfrontendとbackendが同一のNamespace（`default`）内に存在する前提でポリシーを記述しました。**別のNamespace間の通信を制限または許可**したい場合には、NetworkPolicy内で**`namespaceSelector`**を使用します。例えば「あるデータベース用Namespace内のPodは、特定のアプリケーションNamespaceのPodからのみIngressを受け付ける」といった要件を実現できます。

具体的には、目的のNamespaceにラベルを付け、そのラベルで`namespaceSelector`をマッチさせます。加えて、送信元Podの条件を限定するには`podSelector`を同じ`from`または`to`要素内で併記します。先ほどのIngress許可例を、frontendとbackendが異なるNamespaceにいるケースに拡張すると以下のようになります。

- 仮にfrontend Deploymentを`frontend-ns`というNamespaceにデプロイし、backend Deploymentは`backend-ns`に配置しているとします。それぞれのNamespaceにラベルを付与します（例: `frontend-ns`に`role=frontend`、`backend-ns`に`role=backend`など）。
    
- backend-nsで適用するNetworkPolicyの`ingress.from`において、`namespaceSelector: matchLabels: { role: frontend }`と`podSelector: matchLabels: { app: frontend }`を組み合わせて指定します。こうすることで「ラベル`role=frontend`を持つNamespace（=frontend-ns）の中の、ラベル`app=frontend`を持つPod」からのIngress通信だけを許可できます。以下に例を示します。
    
    ```yaml
    ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            role: frontend        # 送信元Namespaceに付けたラベル
        podSelector:
          matchLabels:
            app: frontend         # 送信元Podに付与されたラベル
      ports:
      - protocol: TCP
        port: 80
    ```
    
    上記の`from`ブロックは「`role=frontend`というラベルを持つNamespace内に存在する`app=frontend`ラベルのPod」からのアクセスを許可することを表しています。なお、`namespaceSelector`と`podSelector`を同じレベルで並列に書いてしまうと意味が変わってしまう（それぞれ独立した条件のOR条件になる）ため注意が必要です。必ず上記のように一つの`from`要素の中で両方をネストさせ、**特定Namespace内の特定Pod**というAND条件になるよう記述します。
    
    Kubernetes v1.21以降では前述の通り全Namespaceに`kubernetes.io/metadata.name`ラベルが自動付与されています。このため単一のNamespace名をピンポイントで許可したい場合、例えば:
    
    ```yaml
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: frontend-ns
      podSelector:
        matchLabels:
          app: frontend
    ```
    
    のように書くこともできます。この方法では手動のラベル付与が不要なため手軽ですが、試験環境のバージョンによっては対応していない可能性もあるため、確実を期すならば事前にNamespaceにラベルを設定しておきましょう。
    

## まとめ

- **NetworkPolicyの適用範囲**: リソースが存在する**同一Namespace内のPod**に対してのみ効果があります。他NamespaceのPodには直接影響しません。ただし`namespaceSelector`を使うことで他NamespaceのPodを許可対象に含めることは可能です。
    
- **デフォルト動作**: **ポリシー未適用時は全通信許可**ですが、一つでもNetworkPolicyが適用されると対象Podは**デフォルト拒否**に転じます。isolatedになったPodは、そのNetworkPolicy群で明示的に許可された通信のみ受容します。未選択のPodには影響が及ばない点に注意してください。必要に応じて`podSelector: {}`のポリシーで名前空間全体をデフォルト拒否できます。
    
- **Ingress/Egressの使い分け**: Ingressルールは受信トラフィック、Egressルールは送信トラフィックを制御します。`policyTypes`で制御方向を指定し、不要な方は省略します（デフォルト未指定時はIngressのみ、Egressルール記載時は自動追加）。ポリシーは許可する通信を列挙する**ホワイトリスト方式**で、書かれていない通信はデフォルトで拒否されます。
    
- **重要な要素**: `podSelector`で**対象Pod**を選び、`ingress.from`または`egress.to`で**許可する通信元/先**を指定、`ports`で**ポート/プロトコル**を指定します。記載のように、通信が許可されるにはそれら条件を全て満たす必要があります。`podSelector`や`namespaceSelector`で指定するラベルはユーザが適切に付与したものを使いましょう（Namespace名は自動ラベルで指定可）。
    
- **DNSへの考慮**: Egressを制限する際は**DNS (UDP/TCP 53番)**のクエリが通るようにする必要があります。CoreDNSが動作する`kube-system` Namespaceへのアクセスを許可するポリシーを別途追加することで対処できます。これを怠るとホスト名での通信がすべて失敗するので注意してください。
    
- **検証とトラブルシュート**: NetworkPolicy適用後は`kubectl describe netpol`でポリシー内容を確認したり、実際にPodから通信テストをして期待通りに遮断・許可されることを確認しましょう。CKAD試験では短時間で正確にNetworkPolicyを書く必要があるため、テンプレートを覚えておき、ラベル名やポート番号を迅速に置き換えられるよう練習することをお勧めします。
    

以上、KubernetesのNetworkPolicyの概要と主要なポイントの解説でした。NetworkPolicyは一見複雑ですが、**デフォルト拒否→必要な通信を許可**という基本に忠実にルールを組み立てれば理解しやすくなります。公式ドキュメントの追加例やレシピ集も参照し、様々なパターンのポリシーに慣れておきましょう。試験本番でも落ち着いて、与えられた要件を満たすポリシーを正確に作成できるようにしておいてください。