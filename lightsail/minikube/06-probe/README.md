ご指示の内容に基づき、提供されたコードに基づいて必要な`YAML`ファイルを作成し、`LivenessProbe`や`ReadinessProbe`を設定する方法を明確にご説明します。

この例では、`/healthz`エンドポイントと`/delay`エンドポイントを、あなたが提供したExpress APIのコードで作成した上で、KubernetesにおけるLivenessおよびReadinessのプローブを設定します。

### 1. 提供されたコードに基づく`/healthz`と`/delay`のエンドポイント
`/healthz`（Liveness Probe用）：
- このエンドポイントはシステムが正常に稼働していることを返すだけです。

`/delay`（Readiness Probe用）：
- このエンドポイントは意図的に遅延を発生させて、アプリケーションの準備が整ったかどうかを確認します。

```js
// healthzエンドポイント（LivenessProbe用）
app.get('/healthz', (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
  });
});

// delayエンドポイント（ReadinessProbe用）
app.get('/delay', (req, res) => {
  setTimeout(() => {
    res.status(200).json({
      status: 'success',
      message: '遅延レスポンス完了',
      timestamp: new Date().toISOString(),
    });
  }, 3000); // 3秒の遅延
});
```

### 2. YAMLマニフェスト作成（`kubectl create`での迅速なYAML生成）
次に、`kubectl create`を使用してPodを作成し、そこにLivenessおよびReadinessプローブを設定するためのマニフェストを作成します。

#### 初期のYAML生成
```bash
kubectl run app-pod \
  --image=986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5 \
  --dry-run=client -o yaml > app-pod.yaml
```

#### 必須フィールドの修正（差分形式）
```diff
metadata:
  name: app-pod
  labels:
-   run: app-pod
+   app: nodejs-api

spec:
  containers:
  - image: 986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5
    name: app-container
    ports:
    - containerPort: 8000
+   livenessProbe:
+     httpGet:
+       path: /healthz
+       port: 8000
+     initialDelaySeconds: 5
+     periodSeconds: 5
+     failureThreshold: 3
+   readinessProbe:
+     httpGet:
+       path: /delay
+       port: 8000
+     initialDelaySeconds: 5
+     periodSeconds: 5
+     failureThreshold: 3
```

#### 最終版YAML (`app-pod.yaml`)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
  labels:
    app: nodejs-api
spec:
  containers:
  - image: 986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5
    name: app-container
    ports:
    - containerPort: 8000
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8000
      initialDelaySeconds: 5
      periodSeconds: 5
      failureThreshold: 3
    readinessProbe:
      httpGet:
        path: /delay
        port: 8000
      initialDelaySeconds: 5
      periodSeconds: 5
      failureThreshold: 3
  restartPolicy: Always
```

### 3. Podのデプロイと動作確認

1. **Podの適用**:
   ```bash
   kubectl apply -f app-pod.yaml
   ```

2. **Podが正常に`Running`状態であることを確認**:
   ```bash
   kubectl get pods -w
   ```

   最初は `0/1` 状態で、プローブが成功すると `1/1` になることを確認してください。

3. **LivenessおよびReadinessプローブの動作確認**:
   - **Livenessプローブ**は `/healthz` を定期的に確認し、問題が発生した場合にPodを再起動します。
   - **Readinessプローブ**は `/delay` エンドポイントで遅延をチェックし、サービスが準備完了になるまでトラフィックをルーティングしません。

4. **curlで確認**:
   - `http://localhost:8000/healthz`にアクセスして、正常なレスポンス（`status: ok`）を確認。
   - `http://localhost:8000/delay`にアクセスして、遅延レスポンス（`遅延レスポンス完了`）を確認。

### 4. クリーンアップ

Podを削除して環境をクリーンにします。

```bash
kubectl delete -f app-pod.yaml
```

### まとめ

- `livenessProbe` と `readinessProbe` は、Podのヘルスチェックを管理するために非常に重要な設定です。
- `kubectl create` コマンドを使って迅速にYAMLを生成し、適切にプローブ設定を加えることで、ヘルスチェックを簡単に設定できます。
