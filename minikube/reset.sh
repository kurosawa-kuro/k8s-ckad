#!/bin/bash

# エラーが発生したら即座に終了
set -e

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 定数定義
CLUSTER_NAME="ckad-cluster"
NAMESPACE="ckad-ns"
ECR_REGISTRY="986154984217.dkr.ecr.ap-northeast-1.amazonaws.com"
AWS_REGION="ap-northeast-1"

# ログ関数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# クリーンアップ関数
cleanup() {
    log_info "クリーンアップを開始します..."
    
    kubectl delete -f deployment.yaml --ignore-not-found || log_warn "deployment.yamlの削除に失敗しました"
    kubectl delete secret ecr-registry-secret --namespace=$NAMESPACE --ignore-not-found || log_warn "ECRシークレットの削除に失敗しました"
    kubectl delete namespace $NAMESPACE --ignore-not-found || log_warn "名前空間の削除に失敗しました"
    minikube delete --profile $CLUSTER_NAME || log_warn "Minikubeクラスターの削除に失敗しました"
    
    log_info "クリーンアップが完了しました"
}

# クラスター起動関数
start_cluster() {
    log_info "Minikubeクラスターを起動します..."
    
    minikube start --profile $CLUSTER_NAME
    eval $(minikube docker-env)
    
    log_info "クラスターの起動が完了しました"
}

# 名前空間設定関数
setup_namespace() {
    log_info "名前空間を設定します..."
    
    kubectl create namespace $NAMESPACE
    kubectl config set-context --current --namespace=$NAMESPACE
    
    log_info "名前空間の設定が完了しました"
}

# ECR認証設定関数
setup_ecr_auth() {
    log_info "AWS ECR認証を設定します..."
    
    # ECRログイン
    aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin $ECR_REGISTRY || {
        log_error "ECRログインに失敗しました"
        exit 1
    }
    
    # Kubernetesシークレット作成
    ECR_PASSWORD=$(aws ecr get-login-password --region $AWS_REGION)
    
    kubectl create secret docker-registry ecr-registry-secret \
        --docker-server=$ECR_REGISTRY \
        --docker-username=AWS \
        --docker-password="$ECR_PASSWORD" \
        --namespace=$NAMESPACE || {
            log_error "ECRシークレットの作成に失敗しました"
            exit 1
        }
    
    log_info "ECR認証の設定が完了しました"
}

# 状態確認関数
verify_setup() {
    log_info "設定状態を確認します..."
    
    echo "現在のコンテキスト:"
    kubectl config current-context
    
    echo "クラスター情報:"
    kubectl cluster-info
    
    echo "名前空間一覧:"
    kubectl get ns
    
    echo "現在の名前空間:"
    kubectl config view --minify | grep namespace
    
    log_info "設定状態の確認が完了しました"
}

# メイン処理
main() {
    log_info "Minikubeリセットスクリプトを開始します"
    
    cleanup
    start_cluster
    setup_namespace
    setup_ecr_auth
    verify_setup
    
    log_info "Minikubeリセットスクリプトが正常に完了しました"
}

# スクリプト実行
main