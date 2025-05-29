# Kubernetes 環境変数ハンドリングまとめ（CKAD 対策）

---

## 1. 目的

Kubernetes Pod 内で **環境変数（Environment Variables）** を扱う代表的な 2 パターンを整理します。

| パターン                | 特徴                   | 代表シーン                                    |
| ------------------- | -------------------- | ---------------------------------------- |
| **A. Pod に直接定義**    | 単発テスト・ワンショット Pod に最速 | `kubectl run` で manifest 雛形を出力するとき       |
| **B. ConfigMap 経由** | 本番の設定値を一元管理 & 再利用    | `Deployment` や Job など複数 Pod で同じ値を共有したいとき |

---

## 2. パターン A：Pod へ直接環境変数

### 2‑1 ワンライナーで YAML 生成

```bash
kubectl run envar-demo01 \
  --image=busybox:1.36 \
  --restart=Never \
  --labels=purpose=demonstrate-envars \
  --env=DEMO_GREETING="Hello from the environment" \
  --env=DEMO_FAREWELL="Such a sweet sorrow" \
  --command -- /bin/sh -c 'sleep 3600 && echo $DEMO_GREETING && echo $DEMO_FAREWELL' \
  --dry-run=client -o yaml > envar-demo01.yaml
```

### 2‑2 生成される Pod マニフェスト

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: envar-demo01
  labels:
    purpose: demonstrate-envars
spec:
  restartPolicy: Never
  containers:
  - name: envar-demo-container
    image: busybox:1.36
    command: ["/bin/sh","-c","sleep 3600 && echo $DEMO_GREETING && echo $DEMO_FAREWELL"]
    env:
    - name: DEMO_GREETING
      value: "Hello from the environment"
    - name: DEMO_FAREWELL
      value: "Such a sweet sorrow"
```

> **ポイント**
>
> * `--command -- /bin/sh -c '...'` で **ENTRYPOINT 置換**。
> * `-c` は *string* をシェルスクリプトとして実行するオプション。
> * `--restart=Never` で Job 風ワンショットに。

---

## 3. パターン B：ConfigMap で環境変数を注入

### 3‑1 ConfigMap を作成

```bash
kubectl create configmap envar-demo02-config \
  --from-literal=DEMO_GREETING="Hello from the environment" \
  --from-literal=DEMO_FAREWELL="Such a sweet sorrow" \
  --dry-run=client -o yaml > envar-demo02-config.yaml
```

生成 YAML（抜粋）

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: envar-demo02-config
data:
  DEMO_GREETING: Hello from the environment
  DEMO_FAREWELL: Such a sweet sorrow
```

### 3‑2 Pod から取り込む例

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: envar-demo02
  labels:
    purpose: demonstrate-envars
spec:
  restartPolicy: Never
  containers:
  - name: envar-demo-container
    image: busybox:1.36
    command: ["/bin/sh","-c","sleep 3600 && echo $DEMO_GREETING && echo $DEMO_FAREWELL"]
    envFrom:
      - configMapRef:
          name: envar-demo02-config
```

> **envFrom vs. env**
>
> * `envFrom` はキーを **丸ごと** インポートする最速手段。
> * 個別キーだけ使いたい場合は `env:` + `valueFrom.configMapKeyRef`。

---

## 4. 早見表

| 操作            | 直接定義                   | ConfigMap 経由                      |
| ------------- | ---------------------- | --------------------------------- |
| **宣言場所**      | Pod manifest 内 `env:`  | Pod とは別リソース                       |
| **再利用性**      | 低（Pod 固有）              | 高（複数 Pod で共有）                     |
| **変更時の再デプロイ** | 必須                     | ConfigMap 更新 → Pod 再起動 or Rollout |
| **CKAD 出題率**  | 高（`kubectl run --env`） | 高（`envFrom` & 個別キー参照）             |

---

## 5. よく使うコマンド集

```bash
# 作成
kubectl apply -f envar-demo01.yaml
kubectl apply -f envar-demo02-config.yaml
kubectl apply -f envar-demo02.yaml

# 環境変数確認
echo $(kubectl exec envar-demo01 -- printenv | grep DEMO_)

# ConfigMap の中身を確認
kubectl get configmap envar-demo02-config -o yaml
```

---

## 6. トラブルシューティング

* **値が展開されない** → シェルのクォートを確認 (`'` なら展開されず `"` なら展開)。
* **ConfigMap 更新を Pod に即時反映したい** → `kubectl rollout restart deployment/<name>` などで再起動。

---

## 7. 参考

* Kubernetes 公式: [Configure Pods and Containers Using Environment Variables](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/)
* BusyBox イメージ: [library/busybox on Docker Hub](https://hub.docker.com/_/busybox/)
