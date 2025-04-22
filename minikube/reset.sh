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
DEPLOYMENT_FILE="deployment.yaml"

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

# ファイル存在チェック関数
check_file_exists() {
    if [ ! -f "$1" ]; then
        log_warn "ファイル '$1' が存在しません。このステップはスキップされます。"
        return 1
    fi
    return 0
}

# コマンド実行関数
run_command() {
    local cmd="$1"
    local error_msg="$2"
    
    log_info "コマンドを実行: $cmd"
    if ! eval "$cmd"; then
        log_error "$error_msg"
        return 1
    fi
    return 0
}

# クリーンアップ関数
cleanup() {
    log_info "クリーンアップを開始します..."
    
    # deployment.yamlの存在チェックと削除
    if check_file_exists "$DEPLOYMENT_FILE"; then
        run_command "kubectl delete -f \"$DEPLOYMENT_FILE\" --ignore-not-found" "deployment.yamlの削除に失敗しました" || log_warn "deployment.yamlの削除に失敗しました"
    fi
    
    # シークレットと名前空間の削除
    run_command "kubectl delete secret ecr-registry-secret --namespace=$NAMESPACE --ignore-not-found" "ECRシークレットの削除に失敗しました" || log_warn "ECRシークレットの削除に失敗しました"
    run_command "kubectl delete namespace $NAMESPACE --ignore-not-found" "名前空間の削除に失敗しました" || log_warn "名前空間の削除に失敗しました"
    
    # Minikubeクラスターの削除
    if minikube profile list | grep -q "$CLUSTER_NAME"; then
        run_command "minikube delete --profile $CLUSTER_NAME" "Minikubeクラスターの削除に失敗しました" || log_warn "Minikubeクラスターの削除に失敗しました"
    else
        log_info "Minikubeクラスター '$CLUSTER_NAME' は存在しません"
    fi
    
    log_info "クリーンアップが完了しました"
}

# クラスター起動関数
start_cluster() {
    log_info "Minikubeクラスターを起動します..."
    
    if ! run_command "minikube start --profile $CLUSTER_NAME" "Minikubeクラスターの起動に失敗しました"; then
        log_error "Minikubeクラスターの起動に失敗しました"
        exit 1
    fi
    
    # Docker環境変数の設定（containerd対応）
    log_info "Docker環境変数を設定します..."
    if minikube -p "$CLUSTER_NAME" docker-env >/dev/null 2>&1; then
        eval "$(minikube -p "$CLUSTER_NAME" docker-env)"
        log_info "docker-env を適用しました"
    else
        log_warn "docker-env は containerd では不要なのでスキップします"
    fi
    
    log_info "クラスターの起動が完了しました"
}

# 名前空間設定関数
setup_namespace() {
    log_info "名前空間を設定します..."
    
    if ! run_command "kubectl create namespace $NAMESPACE" "名前空間の作成に失敗しました"; then
        log_error "名前空間の作成に失敗しました"
        exit 1
    fi
    
    if ! run_command "kubectl config set-context --current --namespace=$NAMESPACE" "名前空間の設定に失敗しました"; then
        log_error "名前空間の設定に失敗しました"
        exit 1
    fi
    
    log_info "名前空間の設定が完了しました"
}

# ECR認証設定関数
setup_ecr_auth() {
    log_info "AWS ECR認証を設定します..."
    
    # AWS CLIが利用可能か確認
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLIがインストールされていません"
        exit 1
    fi
    
    # ECRログイン
    if ! run_command "aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY" "ECRログインに失敗しました"; then
        log_error "ECRログインに失敗しました"
        exit 1
    fi
    
    # Kubernetesシークレット作成
    ECR_PASSWORD=$(aws ecr get-login-password --region $AWS_REGION)
    
    if ! run_command "kubectl create secret docker-registry ecr-registry-secret --docker-server=$ECR_REGISTRY --docker-username=AWS --docker-password=\"$ECR_PASSWORD\" --namespace=$NAMESPACE" "ECRシークレットの作成に失敗しました"; then
        log_error "ECRシークレットの作成に失敗しました"
        exit 1
    fi
    
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