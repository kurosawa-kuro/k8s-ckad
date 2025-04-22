# 📘 CKAD試験対策チュートリアル: マルチコンテナPod（Express + BusyBoxサイドカー）

## ✅ 作業ディレクトリ

- `~/dev/k8s-kind-ckad/02-multicontainer-pod`

## ✅ 使用コンテナイメージ

- **メインコンテナ**: Node.js Express API (AWS ECR)
- **サイドカーコンテナ**: BusyBox (Public)

| 項目 | 詳細 |
|------|-------|
| メインイメージ | `986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5` |
| サイドカーイメージ | `busybox:latest` |
| Gitリポジトリ | [container-nodejs-api-8000](https://github.com/kurosawa-kuro/container-nodejs-api-8000) |
| ポート | 8000 |

---

## 🚀 チュートリアル手順

### 📌 Step 1: クラスタの確認・事前準備

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

### 📌 Step 2: AWS ECR認証情報をk8s Secretとして登録

```bash
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin 986154984217.dkr.ecr.ap-northeast-1.amazonaws.com

kubectl create secret generic ecr-registry-secret \
  --from-file=.dockerconfigjson=$HOME/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson
```

- Secretの確認

```bash
kubectl get secrets ecr-registry-secret
```

### 📌 Step 3: YAML初期生成（kubectl create利用）

```bash
cd ~/dev/k8s-kind-ckad/02-multicontainer-pod

kubectl run multicontainer-pod \
  --image=986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5 \
  --dry-run=client -o yaml > multicontainer-pod.yaml
```

### 📌 Step 4: YAML修正（CKAD試験スタイル・差分形式）

```diff
metadata:
  name: multicontainer-pod
  labels:
-   run: multicontainer-pod
+   app: multicontainer-app

spec:
+ imagePullSecrets:
+ - name: ecr-registry-secret

+ volumes:
+ - name: shared-data
+   emptyDir: {}

  containers:
  - image: 986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/container-nodejs-api-8000:v1.0.5
-   name: multicontainer-pod
+   name: express-container
    ports:
    - containerPort: 8000
    volumeMounts:
    - name: shared-data
      mountPath: /usr/src/app/shared

+ - name: busybox-sidecar
+   image: busybox:latest
+   command: ["/bin/sh"]
+   args: ["-c", "while true; do wget -O- http://localhost:8000/posts; echo; sleep 5; done"]
+   volumeMounts:
+   - name: shared-data
+     mountPath: /shared
```

### 📌 Step 5: Podのデプロイ

```bash
kubectl apply -f multicontainer-pod.yaml
kubectl get pods -w
```

### 📌 Step 6: 動作確認

- Express APIへのアクセス確認

```bash
kubectl port-forward pod/multicontainer-pod 8080:8000
```
別ターミナルで

```bash
curl http://localhost:8080/posts
```

- サイドカー動作確認

```bash
kubectl logs multicontainer-pod -c busybox-sidecar
```

### 📌 Step 7: クリーンアップ

```bash
kubectl delete -f multicontainer-pod.yaml
kubectl get pods
```

---

## ✅ CKAD試験対策ポイント再整理

- YAML生成は `kubectl create` を迅速利用
- 必須フィールド（labels, ports, volumes）を明確に指定
- imagePullSecretsの設定を正確に行い、ECR認証対応
- 動作確認まで迅速に行い、正確性を重視

---

## ✅ 推奨環境

| 項目    | バージョン |
|---------|------------|
| OS      | Ubuntu 22.04 |
| kind    | v0.23.0 |
| kubectl | v1.29.x |
| Helm    | v3.14.x |
| Docker  | 24.0+ |
| AWS CLI | v2 |

---

## ✅ GitHubへのPush

```bash
cd ~/dev/k8s-kind-ckad
git add 02-multicontainer-pod
git commit -m "CKAD試験向けマルチコンテナPodチュートリアル"
git push origin main
```

---

## 🎯 チュートリアル達成ゴール

- CKAD試験でのマルチコンテナPod問題を迅速かつ正確に対応できる。
- Kubernetes環境下で実践的なマルチコンテナ管理スキルを習得する。

