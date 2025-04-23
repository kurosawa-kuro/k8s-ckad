# PersistentVolume (PV)・PersistentVolumeClaim (PVC) を使用したデータの永続化

## 目的
このチュートリアルでは、Kubernetesの`PersistentVolume`（PV）と`PersistentVolumeClaim`（PVC）を利用して、Podのライフサイクルを超えてデータを永続化する方法を学びます。

## PV ↔ PVC 容量ルール - 一瞬で思い出すチートシート

| 役者 | 覚え方 | セリフ | 数式イメージ |
|------|--------|--------|--------------|
| **PV**<br>(PersistentVolume) | **Parent**<br>“親” | 「ここまでなら使っていいよ」<br>＝ **上限** を提示 | `上限 = capacity.storage` |
| **PVC**<br>(PersistentVolumeClaim) | **Child**<br>“子” | 「最低これだけ欲しい！」<br>＝ **下限** を要求 | `下限 = resources.requests.storage` |

> **バインド条件**  
> **Parent (上限) ≥ Child (下限)** なら契約成立  
> → PVC `Bound`、Pod で使用可能。

---

### 暗記フック（端的バージョン）

```
PV = Parent（財布のヒモ）
PVC = Child（おこづかい請求）
契約は「Parent ≥ Child」で OK
```

- **符号の向きだけが混乱ポイント**  
  - “≥” を思い出せば解決。
- こう覚えれば、容量トラブルのほとんどは即判断できます。

## 使用イメージ
- **メインイメージ**: busybox、nginx（パブリックイメージ）
- **ポート**: 80（nginx）

## 作業ディレクトリ
作業ディレクトリは次の通りです：
```bash
~/dev/k8s-ckad/minikube/07-volume-pvc
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
    app: nginx
spec:
  containers:
  - name: nginx-container
    image: nginx:latest
    ports:
    - containerPort: 80
    volumeMounts:
    - mountPath: /usr/share/nginx/html
      name: app-storage
  volumes:
  - name: app-storage
    persistentVolumeClaim:
      claimName: app-pvc
```

## 動作確認手順

1. **Minikubeクラスターの起動確認**:
```bash
minikube status
# 起動していない場合は
minikube start
```

2. **PVとPVC,Podの作成**:
```bash
kubectl apply -f pv.yaml
kubectl apply -f pvc.yaml
kubectl apply -f pod-with-pvc.yaml
```

3. **PVとPVCの状態確認**:
```bash
kubectl get pv
kubectl get pvc
```

4. **Pod内でファイルの書き込み**:
```bash
kubectl exec -it app-pod -- sh
echo "test data" > /usr/share/nginx/html/test.txt
```

5. **Pod削除後のデータ確認**:
```bash
kubectl delete pod app-pod
kubectl apply -f pod-with-pvc.yaml
kubectl exec -it app-pod -- cat /usr/share/nginx/html/test.txt
```

## 実証方法：PVCの動作確認

以下の手順で、PVCの動作を詳細に確認できます：

### 1. PVCを使用したPodの作成とデータ書き込み

```bash
# PVCを使用するPodを作成
kubectl apply -f pod-with-pvc.yaml

# Pod内でデータを書き込む
kubectl exec -it app-pod -- sh
echo "test data" > /usr/share/nginx/html/test.txt
exit

# データが書き込まれたことを確認
kubectl exec -it app-pod -- cat /usr/share/nginx/html/test.txt
```

### 2. PVCのマウントを外したPodの作成

`pod-without-pvc.yaml`を作成します：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod-no-volume
  labels:
    app: nginx
spec:
  containers:
  - name: nginx-container
    image: nginx:latest
    ports:
    - containerPort: 80
  # volumeMountsとvolumesセクションをコメントアウト
```

```bash
# 元のPodを削除
kubectl delete pod app-pod

# ボリュームマウントなしのPodを作成
kubectl apply -f pod-without-pvc.yaml

# データにアクセスできないことを確認
kubectl exec -it app-pod-no-volume -- ls /usr/share/nginx/html/test.txt
# ファイルが見つからないエラーが表示される
```

### 3. 再度PVCをマウントしたPodの作成

```bash
# ボリュームマウントなしのPodを削除
kubectl delete pod app-pod-no-volume

# 元のPod（PVCマウントあり）を再作成
kubectl apply -f pod-with-pvc.yaml

# データが再びアクセスできることを確認
kubectl exec -it app-pod -- cat /usr/share/nginx/html/test.txt
# "test data"が表示される
```

この実証により、以下のことが確認できます：

1. PVCはPodとは独立したリソースである
2. Podが削除されても、PVCとデータは保持される
3. PodからPVCのマウントを外すと、データにアクセスできない
4. 再度PVCをマウントすると、以前のデータにアクセスできる

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

### 2. ボリュームマウントエラー
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
# Minikubeのホストマシンに接続
minikube ssh
ls -la /mnt/data
```

### 3. Minikube固有のトラブルシューティング

1. **Minikubeの再起動**:
```bash
minikube stop
minikube start
```

2. **Minikubeのリセット**:
```bash
minikube delete
minikube start
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

## 追加演習（CKAD試験対策）

1. **busyboxを使用したデータ永続化の確認**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox-pod
  labels:
    app: busybox
spec:
  containers:
  - name: busybox-container
    image: busybox
    command: ["/bin/sh", "-c", "while true; do sleep 3600; done"]
    volumeMounts:
    - mountPath: /data
      name: app-storage
  volumes:
  - name: app-storage
    persistentVolumeClaim:
      claimName: app-pvc
```

2. **異なるアクセスモードのPVC作成**:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc-rwo
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard
```