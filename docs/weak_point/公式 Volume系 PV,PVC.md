# Kubernetes PV / PVC / StorageClass — CKAD 速習ノート

> **狙い**：公式サンプルをそのまま動かしながら **作る → 使う → 壊す** の流れで学習し、CKAD 試験対策を最速で終わらせる。

---

## 0. 学習ロードマップ

|Step|触るリソース|習得ポイント|
|---|---|---|
|1|**静的 PV + PVC** (hostPath)|手動で PV を用意し Pod にバインドする基本|
|2|**Pod で利用**|`volumeMounts` と `persistentVolumeClaim` の書き方|
|3|**StorageClass → 動的 PV**|PVC だけ apply して PV を自動生成させる流れ|
|4|**ReclaimPolicy / 容量拡張**|データライフサイクルとオンラインリサイズ|

---

## 1️⃣ 静的プロビジョニング — **PV と PVC** を自分で書く

以下は公式ドキュメント _hostPath_ サンプルを 5 Gi に縮小したもの。

### 1-1. `pv.yaml`

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-hostpath-01
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain   # PVC 削除後もデータ保持
  storageClassName: manual               # 空文字でも可
  hostPath:
    path: /mnt/data
```

### 1-2. `pvc.yaml`

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: demo-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: manual
```

```bash
kubectl apply -f pv.yaml
kubectl apply -f pvc.yaml
kubectl get pv,pvc   # Bound になれば成功
```

> **覚えること**
> 
> - `storageClassName` が PV と PVC を結び付ける鍵。
>     
> - PV の accessModes は PVC の要求を満たすか上位互換であること。
>     

---

## 2️⃣ Pod からクレームを使う

### `mypod.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-with-volume
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - mountPath: /usr/share/nginx/html
      name: webcontent
  volumes:
  - name: webcontent
    persistentVolumeClaim:
      claimName: demo-pvc
```

```bash
kubectl apply -f mypod.yaml
kubectl exec -it nginx-with-volume -- df -hT /usr/share/nginx/html
```

---

## 3️⃣ 動的プロビジョニング — **StorageClass → PVC のみ**

### 3-1. `sc.yaml`（テンプレート）

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: example-gp2
provisioner: kubernetes.io/aws-ebs   # 環境に合わせて変更
parameters:
  type: gp2
allowVolumeExpansion: true
```

### 3-2. `pvc-dyn.yaml`

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: demo-claim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: example-gp2
  resources:
    requests:
      storage: 8Gi
```


# pvc-dyn-local.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: demo-claim
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 1Gi
  # storageClassName を空または default SC 名へ
  storageClassName: ""   # 省略すると default が使われる
  
```bash
kubectl apply -f sc.yaml
kubectl apply -f pvc-dyn.yaml
watch kubectl get pvc,pv
```

数秒後、PVC が **Bound** になり、プロビジョナーが自動生成した PV も確認できる。

> **kind を使う場合**  
> デフォルトで `standard` (`rancher.io/local-path`) StorageClass が入っているので、`sc.yaml` を省略しても動作する。

---

## 4️⃣ 運用 Tips

### 4-1. ReclaimPolicy 早見表

|ポリシー|PVC 削除後|主な用途|
|---|---|---|
|`Delete` (デフォルト)|PV と実ストレージを削除|テストなど|
|`Retain`|PV を Released 状態で保持|重要データ|
|`Recycle`|**非推奨**|ほぼ使用しない|

### 4-2. オンライン容量拡張

1. StorageClass に `allowVolumeExpansion: true` を設定
    
2. `kubectl edit pvc demo-claim` で `storage` 値を増やす
    
3. Pod が再スケジュールされるとファイルシステムも自動リサイズ
    

---

## 5️⃣ CLI チートシート

```bash
# フィールドを調べる
kubectl explain pvc.spec
kubectl explain sc.spec

# 雛形 YAML を生成
kubectl create pvc demo --size=1Gi --access-modes=RWO --dry-run=client -o yaml > pvc.yaml
```

---

### まとめ

1. **静的 → 動的** の順で手を動かすと仕組みが一気に腑に落ちる。
    
2. CKAD では PVC 作成・修正・リサイズが頻出課題。
    
3. Pod 側は `claimName` を書くだけで完了 — あとは PV/PVC のマッチングルールを覚えれば十分。
    

---

> 追加のリクエストがあれば教えてください！