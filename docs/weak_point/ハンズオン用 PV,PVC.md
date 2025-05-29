# Kubernetes **PV / PVC** 速習ドキュメント（ハンズオン版）

> _公式 YAML を「ほぼそのまま」活かしつつ、  
> CKAD 実戦とローカル検証が **確実に動く最小改訂** を入れた学習用テンプレート。_

---

## 0. 学習ロードマップ

|Step|触るリソース|学ぶこと|
|---|---|---|
|1|**静的 PV + PVC**（`hostPath` 例）|手動ストレージを Pod に渡す基礎|
|2|**Pod で利用**|`persistentVolumeClaim` ブロック|
|3|**StorageClass → 動的 PV**|PVC だけで自動プロビジョニング|
|4|**ReclaimPolicy / Expansion**|Retain／Delete、オンライン容量拡張|

---

## 1️⃣ 静的 provision ―― **PV と PVC を書いてバインド**

### 公式サンプルを「確実に動く」形に最小修正

|公式|落とし穴|学習用修正版|
|---|---|---|
|NFS + Recycle|NFS サーバー必須 / Recycle は非推奨|**hostPath + Retain**|
|PV=5 Gi / PVC=8 Gi|サイズ不一致で Pending|**どちらも 1 Gi**|
|selector ラベル要求|PV に無いと Pending|**selector 行を削除**|
|storageClassName=slow|クラスタ側に無い場合 Pending|**空文字 ""** で静的扱い|

### ① PV — _pv.yaml_

```yaml
apiVersion: v1                    # ← Core API グループ
kind: PersistentVolume            # ← クラスタスコープの PV
metadata:
  name: demo-pv                   # ← PV 名 (PVC と 1 対 1 で結ばれる)
spec:
  capacity:
    storage: 1Gi                  # ← 提供サイズ (PVC 要求≦ここ)
  volumeMode: Filesystem          # ← Pod にはディレクトリとして見える
  accessModes: [ReadWriteOnce]    # ← 1 ノードから read-write
  persistentVolumeReclaimPolicy: Retain   # ← PVC 削除後もデータ保持
  storageClassName: ""            # ← 静的 PV は空文字が定番
  hostPath:                       # ← 既存ディレクトリをバインド
    path: /tmp/demo-data          # ← ノードに mkdir しておく
```

### ② PVC — _pvc.yaml_

```yaml
apiVersion: v1                    # ← Core API
kind: PersistentVolumeClaim
metadata:
  name: demo-pvc                  # ← Pod から claimName で参照
spec:
  accessModes: [ReadWriteOnce]    # ← PV と同じ (or 互換) モード必須
  resources:
    requests:
      storage: 1Gi                # ← PV.capacity≧この値 でマッチ
  storageClassName: ""            # ← "" なので空文字 PV だけ対象
```

```bash
# 1. ノードにディレクトリを用意（kind の例）
minikube -p ckad-cluster ssh           # -p/--profile で明示
sudo mkdir -p /tmp/demo-data

# 2. 適用
kubectl apply -f pv.yaml -f pvc.yaml
kubectl get pv,pvc          # Both Bound
```

---

## 2️⃣ **Pod で利用** — “Claims As Volumes”

公式 `mypod.yaml` を claim 名だけ合わせてそのまま使用。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: demo-pod
spec:
  containers:
    - name: web
      image: nginx
      volumeMounts:
        - mountPath: /data            # 任意
          name: myvol
  volumes:
    - name: myvol
      persistentVolumeClaim:
        claimName: demo-pvc
```

```bash
kubectl apply -f mypod.yaml
kubectl exec -it demo-pod -- touch /data/ok
docker exec -it kind-control-plane ls /tmp/demo-data  # ← ok が見える
```

> **覚える行はたった 1 行**  
> `persistentVolumeClaim.claimName: <PVC 名>`

---

## 3️⃣ 動的 provision ―― **StorageClass ＋ PVC だけ**

公式 StorageClass テンプレートを最小化。  
※動く CSI driver 名に変更してください。

### ① StorageClass — _sc.yaml_

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast
provisioner: kubernetes.io/aws-ebs   # 例：EBS CSI なら ebs.csi.aws.com
allowVolumeExpansion: true
reclaimPolicy: Delete
```

### ② PVC — _pvc-dyn.yaml_ （PVC だけ！）

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: fast-claim
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: fast
  resources:
    requests:
      storage: 2Gi
```

```bash
kubectl apply -f sc.yaml -f pvc-dyn.yaml
kubectl get pvc,pv    # fast-claim Bound / pvc-xxxxx PV 自動生成
```

---

## 4️⃣ 運用 Tips

|操作|手順|
|---|---|
|**ReclaimPolicy の切替**|`kubectl patch pv demo-pv -p '{"spec":{"persistentVolumeReclaimPolicy":"Delete"}}'`|
|**オンライン拡張**|`kubectl edit pvc fast-claim` → `storage: 4Gi`|
|**PV/PVC フィールド確認**|`kubectl explain pvc.spec` / `kubectl explain pv.spec`|

### リクレームポリシー早見

|Policy|PVC 削除後|用途|
|---|---|---|
|Delete(既定)|PV・実ストレージとも削除|短命テスト|
|Retain|PV は Released、手動で再利用 or 物理削除|バックアップ取得後に再利用|
|Recycle(廃止予定)|rm -rf で初期化|※推奨されず|

---

## 5️⃣
---

### 最小ポイントまとめ

1. **静的 PV** は `hostPath + storageClassName:""` が一番動かしやすい
    
2. **Pod 側は claimName を書くだけ** — マウント先は自由
    
3. **動的** は StorageClass を用意 → PVC だけ出す
    
4. CKAD では “サイズ変更” “ReclaimPolicy” “StorageClass 名の指定” が頻出
    

---

> **これで “公式 YAML に忠実＋必ず動く” ハンズオン用シートになりました。**  
> さらに別タイプ（NFS, ReadWriteMany, Block Volume など）を試したい場合はお気軽に！