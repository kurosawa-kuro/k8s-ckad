#!/usr/bin/env bash
set -euo pipefail

PROFILE="ckad-cluster"
NS="ckad-ns"
REGISTRY="986154984217.dkr.ecr.ap-northeast-1.amazonaws.com"

# 0‑1. 既存リソース削除
kubectl delete deployment,node,svc,pod,role,rolebinding,sa --all -n "$NS" --ignore-not-found
kubectl delete secret ecr-registry-secret -n "$NS" --ignore-not-found
kubectl delete namespace "$NS" --ignore-not-found || true
minikube delete --profile "$PROFILE" || true

# 0‑2. クラスター再作成
minikube start --profile "$PROFILE"

# 0‑3. docker-env 切替え (ECR ログイン用)
eval "$(minikube -p "$PROFILE" docker-env)"

# 0‑4. 名前空間作成
kubectl create namespace "$NS"

# 0‑5. ECR ログイン & Secret 作成
aws ecr get-login-password --region ap-northeast-1 | \
  docker login --username AWS --password-stdin "$REGISTRY"
ECR_PASS=$(aws ecr get-login-password --region ap-northeast-1)
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server="$REGISTRY" \
  --docker-username=AWS \
  --docker-password="$ECR_PASS" \
  -n "$NS"

# 0‑6. Context を ckad-ns に固定
kubectl config set-context --current --namespace="$NS"

echo "✅ リセット + 準備完了 (${PROFILE}/${NS})"