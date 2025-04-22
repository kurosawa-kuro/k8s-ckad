# PersistentVolume (PV)・PersistentVolumeClaim (PVC) を使用したデータの永続化

## 目的
このチュートリアルでは、Kubernetesの`PersistentVolume`（PV）と`PersistentVolumeClaim`（PVC）を利用して、Podのライフサイクルを超えてデータを永続化する方法を学びます。

## 使用イメージ
- **メインイメージ**: Express API（ECR）
- **ポート**: 8000

## 作業ディレクトリ
作業ディレクトリは次の通りです：
```bash
~/dev/k8s-kind-ckad/07-volume-pvc
```

## YAMLファイル作成手順

1. **PersistentVolumeの作成**:
   `pv.yaml`を作成します：

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: app-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /mnt/data
```

2. **PersistentVolumeClaimの作成**:
   `pvc.yaml`を作成します：

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard
```

3. **Podの作成**:
   `pod-with-pvc.yaml`を作成します：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
  labels:
    app: nodejs-api
spec:
  imagePullSecrets:
  - name: ecr-registry-secret
  containers:
  - name: app-container
    image: 986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5
    ports:
    - containerPort: 8000
    volumeMounts:
    - mountPath: /usr/src/app/data
      name: app-storage
  volumes:
  - name: app-storage
    persistentVolumeClaim:
      claimName: app-pvc
```

4. **Deploymentの作成（オプション）**:
   `deployment-with-pvc.yaml`を作成します：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-pod
  template:
    metadata:
      labels:
        app: app-pod
    spec:
      containers:
      - name: app-container
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
        - name: app-storage
          mountPath: /usr/src/app/data
      volumes:
      - name: app-storage
        persistentVolumeClaim:
          claimName: app-pvc
```

## 動作確認手順

1. **PVとPVCの作成**:
```bash
kubectl apply -f pv.yaml
kubectl apply -f pvc.yaml
```

2. **Podのデプロイ**:
```bash
kubectl apply -f pod-with-pvc.yaml
# または
kubectl apply -f deployment-with-pvc.yaml
```

3. **PVとPVCの状態確認**:
```bash
kubectl get pv
kubectl get pvc
```

4. **Pod内でファイルの書き込み**:
```bash
kubectl exec -it app-pod -- sh
echo "test data" > /usr/src/app/data/test.txt
```

5. **Pod削除後のデータ確認**:
```bash
kubectl delete pod app-pod
kubectl apply -f pod-with-pvc.yaml
kubectl exec -it app-pod -- cat /usr/src/app/data/test.txt
```

## エラー対応

### 1. PVC更新エラー
PVCは作成後に変更できないリソースです。変更が必要な場合は、以下の手順で対応します：

1. **既存のPVCを削除**:
```bash
kubectl delete pvc app-pvc
```

2. **新しいPVCを作成**:
```bash
kubectl apply -f pvc.yaml
```

### 2. イメージプル失敗
ECRからのイメージプルに失敗する場合は、以下を確認します：

1. **ECRログイン確認**:
```bash
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin 986154984217.dkr.ecr.ap-northeast-1.amazonaws.com
```

2. **Secret作成**:
```bash
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=986154984217.dkr.ecr.ap-northeast-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region ap-northeast-1)
```

### 3. ボリュームマウントエラー
ボリュームマウントに失敗する場合は、以下を確認します：

1. **PVの状態確認**:
```bash
kubectl describe pv app-pv
```

2. **PVCの状態確認**:
```bash
kubectl describe pvc app-pvc
```

3. **ホストパスの確認**:
```bash
ls -la /mnt/data
```

## CKAD試験対策の重要ポイント

1. **YAML生成のスピード**:
   - `kubectl create`を使用して初期YAMLを生成
   - 必要なフィールドを素早く修正

2. **リソース管理**:
   - `kubectl get`で状態確認
   - `kubectl describe`でトラブルシューティング

3. **データ永続化の確認**:
   - データの書き込みテスト
   - Pod再作成後のデータ確認

4. **エラー対応**:
   - エラーメッセージの理解
   - 適切な対処方法の選択
   - トラブルシューティングコマンドの活用