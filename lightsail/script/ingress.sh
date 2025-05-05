#!/bin/bash

# エラーが発生したら即座に終了
set -e

echo "=== Ingress Controller Setup ==="

# 必要なツールの確認
echo "Checking required tools..."
if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo "helm is not installed"
    exit 1
fi

# Ingressコントローラーのインストール
echo "Installing Ingress Controller..."
helm upgrade --install ingress-nginx ingress-nginx \
    --repo https://kubernetes.github.io/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace

# ノードIPの取得
echo "Getting node IP..."
NODE_IP=$(kubectl get nodes ckad-cluster -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
if [ -z "$NODE_IP" ]; then
    echo "Failed to get node IP"
    exit 1
fi

# /etc/hostsの更新
echo "Updating /etc/hosts..."
if ! grep -q "path-ingress.info" /etc/hosts; then
    echo "$NODE_IP path-ingress.info" | sudo tee -a /etc/hosts
else
    echo "path-ingress.info entry already exists in /etc/hosts"
fi

# Ingressコントローラーの状態確認
echo "Checking Ingress Controller status..."
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=120s

# サービスの状態確認
echo "Checking Ingress Controller service..."
kubectl get svc -n ingress-nginx

echo "=== Setup Complete ==="
echo "Ingress Controller is ready"
echo "You can access the Ingress using: http://path-ingress.info"
echo "Note: You may need to wait a few minutes for the LoadBalancer to be provisioned"
