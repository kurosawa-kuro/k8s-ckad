#!/bin/bash

# ======== 0. クリーンアップ ========
# 前回の構成を削除して、クリーンな状態で再スタート

kubectl delete -f deployment.yaml --ignore-not-found
kubectl delete secret ecr-registry-secret --namespace=ckad-ns --ignore-not-found
kubectl delete namespace ckad-ns --ignore-not-found
minikube delete --profile ckad-cluster

# ======== 1. クラスター起動 ========
minikube start --profile ckad-cluster
eval $(minikube docker-env)

# ======== 2. Namespace 作成・設定 ========
kubectl create namespace ckad-ns
kubectl config set-context --current --namespace=ckad-ns

# ======== 3. AWS ECR 認証：Dockerログイン ========
aws ecr get-login-password --region ap-northeast-1 \
| docker login --username AWS \
  --password-stdin 986154984217.dkr.ecr.ap-northeast-1.amazonaws.com

# ======== 4. Kubernetes Secret 作成（imagePull用） ========
ECR_PASSWORD=$(aws ecr get-login-password --region ap-northeast-1)

kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=986154984217.dkr.ecr.ap-northeast-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password="$ECR_PASSWORD" \
  --namespace=ckad-ns

# ======== 5. 確認 ========
kubectl config current-context
kubectl cluster-info

kubectl get ns
kubectl config view --minify | grep namespace













了解！以下に、**minikubeプロファイル操作からECR認証のKubernetesシークレット作成までを整理した完全ガイド**をまとめました👇  
CKADの練習環境やECR連携PoCにもそのまま使えます🔥

---

# ✅ Kubernetes × minikube × ECR 認証設定ガイド

---

## 🔹 1. クラスター（プロファイル）管理

### ✅ プロファイル一覧の確認

```bash
minikube profile list
```

### ✅ 既存プロファイル（例：ckad-cluster）の削除と再作成

```bash
minikube delete --profile ckad-cluster
minikube start --profile ckad-cluster
```

※練習の初期化として有効

---

## 🔹 2. `kubectl` の接続先確認

### ✅ 現在の `kubectl` context とクラスタ情報を確認

```bash
kubectl config current-context
kubectl cluster-info
```

→ `minikube` または `ckad-cluster` のような context が返ればOK

---

## 🔹 3. DockerとECR連携の準備（minikube内でビルド or プッシュする場合）

### ✅ Docker環境をminikubeに切り替える（ホスト → minikube）

```bash
eval $(minikube docker-env)
```

---

## 🔹 4. AWS ECR 認証＆Kubernetes Secret作成

### ✅ ECRログイン（直接ログイン）

```bash
aws ecr get-login-password --region ap-northeast-1 \
| docker login --username AWS --password-stdin 986154984217.dkr.ecr.ap-northeast-1.amazonaws.com
```

### ✅ Kubernetes Secret作成（PodでECRイメージをpullするため）

```bash
# 1. 認証情報を変数に保存
ECR_PASSWORD=$(aws ecr get-login-password --region ap-northeast-1)

# 2. Secret作成
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=986154984217.dkr.ecr.ap-northeast-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password="$ECR_PASSWORD"
```

### ✅ Secret使用例（Pod内でpullする場合のYAML一部）

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ecr-pod
spec:
  containers:
    - name: app
      image: 986154984217.dkr.ecr.ap-northeast-1.amazonaws.com/my-app:latest
  imagePullSecrets:
    - name: ecr-registry-secret
```

---

## 🧼 補足

- `kubectl delete secret ecr-registry-secret` で削除可能
- `--namespace=<name>` 付きでSecretを別Namespaceに作成することもOK

---

## 🎯 練習サイクル例（最短手順）

```bash
minikube delete --profile ckad-cluster
minikube start --profile ckad-cluster

eval $(minikube docker-env)

aws ecr get-login-password --region ap-northeast-1 \
| docker login --username AWS --password-stdin 986154984217.dkr.ecr.ap-northeast-1.amazonaws.com

# 1. 認証情報を変数に保存
ECR_PASSWORD=$(aws ecr get-login-password --region ap-northeast-1)

# 2. Secret作成
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=986154984217.dkr.ecr.ap-northeast-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password="$ECR_PASSWORD"

kubectl create namespace ckad-ns
kubectl config set-context --current --namespace=ckad-ns

# 以降、Deployment → Service → ECR連携Podを適用
```

---

この構成で、**CKAD練習・ECR連携・実環境模擬**の全部に対応できます🙆‍♂️  
必要なら「`imagePullSecrets` を含んだDeploymentテンプレ」も出すよ！やる？🔥