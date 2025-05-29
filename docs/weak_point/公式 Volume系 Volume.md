# Kubernetes Volumes – CKAD 速習ノート

> **狙い**: コード(YAML)はそのまま保持し、説明文だけを整理。ハンズオン → CKAD 本番まで最短で役立つように構成しました。

---

## 0. 学習ロードマップ

| ステップ | 触るボリューム         | 学ぶこと                         |
| ---- | --------------- | ---------------------------- |
| 1    | **emptyDir**    | Pod 内共有・一時キャッシュ              |
| 2    | **ConfigMap**   | 設定ファイル／環境変数注入                |
| 3    | **hostPath**    | ホスト共有とセキュリティ注意               |
| 4    | **downwardAPI** | Pod メタデータのファイル受け渡し _(コード割愛)_ |
| 5    | **PVC(PV+PVC)** | 永続ストレージ運用 _(別ドキュメント)_        |

---

## 1. emptyDir — Pod 内一時ディスク

### 典型ユース

- 2 コンテナ間キャッシュ共有
    
- バッチ中間ファイル置き場
    

### ひな形コマンド

```bash
kubectl run test-pd \
  --image=busybox:1.36 \
  --restart=Never \
  --command -- sh -c "sleep infinity"
```

YAML を編集して以下にするだけ。

```yaml
apiVersion: v1                    # コア API
kind: Pod                         # リソース種別
metadata:
  name: test-pd
spec:
  containers:
    image: busybox:1.36
    command: ["sh","-c","sleep infinity"]
    name: test-container
    volumeMounts:
      - name: cache-volume
        mountPath: /cache
  volumes:
    - name: cache-volume
      emptyDir:
        sizeLimit: 500Mi
```

#### 実行確認

```bash
kubectl apply -f emptydir.yaml
kubectl exec -it test-pd -- /bin/sh   # /cache に書けば Pod 存続中のみ保持
```

---

## 2. ConfigMap — 設定をファイルで注入

### ユースケース

- ログレベルやエンドポイントの動的設定
    
- 複数キーを 1 ディレクトリに展開
    

### 作成コマンド → ひな形 Pod 作成

```bash
kubectl create configmap log-config --from-literal=log_level=debug
kubectl run configmap-pod \
  --image=busybox:1.28 \
  --restart=Never \
  --command -- sh -c "sleep infinity"
```

YAML 完成形:

```yaml
#######################################
# ① ConfigMap — 設定の実体
#######################################
apiVersion: v1
kind: ConfigMap
metadata:
  name: log-config
data:
  log_level: "debug"
---
#######################################
# ② Pod — ConfigMap をファイルとして利用
#######################################
apiVersion: v1
kind: Pod
metadata:
  name: configmap-pod
spec:
  containers:
    - name: test
      image: busybox:1.28
      command: ['sh','-c','echo "The app is running!" && tail -f /dev/null']
      volumeMounts:
        - name: config-vol
          mountPath: /etc/config
  volumes:
    - name: config-vol
      configMap:
        name: log-config
        items:
          - key: log_level        # 抜き出すキー
            path: log_level.conf  # /etc/config/log_level.conf に保存
```

|フィールド|役割|
|---|---|
|`key`|ConfigMap から取り出すキー名|
|`value`|ConfigMap に保存された実データ (`debug`)|
|`path`|コンテナ内で保存するファイル名|

---

## 3. hostPath — ホストディレクトリ直接マウント

### 注意点

- 本番は **最小限 & readOnly 推奨**
    
- ディレクトリが無いと Pod は Pending
    

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-example-linux
spec:
  os: { name: linux }
  nodeSelector:
    kubernetes.io/os: linux
  containers:
    - name: example-container
      image: registry.k8s.io/test-webserver
      volumeMounts:
        - name: example-volume
          mountPath: /foo
          readOnly: true
  volumes:
    - name: example-volume
      hostPath:
        path: /data/foo
        type: Directory
```

---

## 4. kubectl exec チート

```
-i  = Interactive (stdin)
-t  = TTY (端末制御)
--  = ここからコンテナ内コマンド
/bin/sh = 最小シェル（busybox でも存在）
```

例: `kubectl exec -it mypod -- /bin/sh`

---

### おさらい

- **emptyDir → ConfigMap → hostPath** の 3 つで Volume 基礎を網羅
    
- CKAD の主力は ConfigMap と PVC。hostPath は補足レベル
    
- `kubectl explain` と `--dry-run=client -o yaml` を使うと試験中の YAML 手書きが激減