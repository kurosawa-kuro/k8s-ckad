以下に、**Express API ECR前提で、NetworkPolicyによる通信制御**を実現するための正解のYAMLマニフェストを示します。

### 1. **初期YAML生成コマンド**

まずはExpress API用のDeploymentを生成します。

```bash
kubectl create deployment express-api --image=986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5 --dry-run=client -o yaml > deployment.yaml
```

このコマンドで`deployment.yaml`が生成されます。

### 2. **修正されたDeploymentのYAML（差分形式）**

次に、生成された`deployment.yaml`を以下の内容で修正します。

```diff
spec:
  replicas: 2
  selector:
    matchLabels:
+      app: express-api
  template:
    metadata:
      labels:
+        app: express-api
    spec:
      containers:
        - name: container-nodejs-api-8000
          image: 986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5
+          ports:
+            - containerPort: 8000
```

**修正内容**:
- `replicas`の設定を`2`にして、2つのPodを作成
- `app: express-api`というラベルを追加
- コンテナの`containerPort`を8000として明示

### 3. **Deploymentマニフェスト（最終版）**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: express-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: express-api
  template:
    metadata:
      labels:
        app: express-api
    spec:
      containers:
        - name: container-nodejs-api-8000
          image: 986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5
          ports:
            - containerPort: 8000
```

### 4. **NetworkPolicyの作成**

次に、Pod間の通信を制御するNetworkPolicyを作成します。

#### 4.1 **デフォルトのIngress通信を拒否するNetworkPolicy**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress: []
```

この設定は、すべてのIngress通信を拒否するものです。新たにIngressのルールを追加することで通信を許可します。

#### 4.2 **特定のラベルを持つPodからのみ通信を許可するNetworkPolicy**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-express-api-ingress
spec:
  podSelector:
    matchLabels:
      app: express-api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          access: allowed
    ports:
    - protocol: TCP
      port: 8000
```

この設定では、`access: allowed`というラベルを持つPodからのみ、`express-api`への通信が許可されます。

### 5. **Serviceの作成**

Express APIのPodにアクセスするためのServiceを作成します。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: express-service
spec:
  selector:
    app: express-api
  ports:
    - protocol: TCP
      port: 8000
      targetPort: 8000
  type: ClusterIP
```

このServiceは、Express APIへのアクセスを提供します。

### 6. **適用手順**

1. **Deploymentの適用**:

```bash
kubectl apply -f deployment.yaml
```

2. **NetworkPolicyの適用**（デフォルトでIngress通信を拒否）:

```bash
kubectl apply -f default-deny-ingress.yaml
kubectl apply -f allow-express-api-ingress.yaml
```

3. **Serviceの適用**:

```bash
kubectl apply -f service.yaml
```

### 7. **動作確認**

- **通信拒否の確認**（`test-deny` Podを作成して通信を試みる）:

```bash
kubectl run test-deny --image=busybox --restart=Never --rm -it -- wget -qO- http://express-api:8000/posts
```

- **通信許可の確認**（`allowed-test` Podを作成して通信を試みる）:

```bash
kubectl run allowed-test --labels access=allowed --image=busybox --restart=Never --rm -it -- wget -qO- http://express-api:8000/posts
```

これにより、`access=allowed`ラベルが付けられたPodのみが通信可能であることを確認できます。

### 8. **削除手順**

- **Deployment、NetworkPolicy、Serviceの削除**:

```bash
kubectl delete -f deployment.yaml
kubectl delete -f default-deny-ingress.yaml
kubectl delete -f allow-express-api-ingress.yaml
kubectl delete -f service.yaml
```

---

### 9. **CKAD試験の重要ポイント**

- `kubectl create`や`kubectl run`コマンドを使って初期YAMLを迅速に生成し、必要な部分を修正する
- Pod、Service、NetworkPolicyの適切な設定と動作確認を行う
- 作業スピードと正確性が合格の鍵

### 10. **今後の学習ステップ**

- マルチコンテナPodの作成
- ConfigMap/Secretとの設定連携
- Liveness/Readiness Probeの活用
- Service / IngressによるPodの公開

---

以上が、**CKAD試験対策のNetworkPolicyによる通信制御**に関する正解のYAMLマニフェストです。