#!/usr/bin/env bash
# reset.sh : CKAD 用 Minikube クラスターを作り直すユーティリティ
set -Eeuo pipefail
IFS=$'\n\t'

###############################################################################
# ✨ 設定（環境変数で上書き可）
###############################################################################
CLUSTER_NAME="${CLUSTER_NAME:-ckad-cluster}"
NAMESPACE="${NAMESPACE:-ckad-ns}"
ECR_REGISTRY="${ECR_REGISTRY:-986154984217.dkr.ecr.ap-northeast-1.amazonaws.com}"
AWS_REGION="${AWS_REGION:-ap-northeast-1}"
DEPLOYMENT_FILE="${DEPLOYMENT_FILE:-deployment.yaml}"
MINIKUBE_DRIVER="docker"   # 既定：docker（containerd の場合でも可）
CONTAINER_RUNTIME=""       # 空なら Minikube 既定（最新版は containerd）

# Minikube リソース設定（環境変数で上書き可）
MINIKUBE_CPUS="${MINIKUBE_CPUS:-8}"           # 推奨: 6-8 cores
MINIKUBE_MEMORY="${MINIKUBE_MEMORY:-10000}"   # 推奨: 10 GiB (MiB単位)
MINIKUBE_DISK_SIZE="${MINIKUBE_DISK_SIZE:-20000}"  # 20 GiB

###############################################################################
# 🖍️  ログ用装飾
###############################################################################
# 端末が no-color の場合を考慮
if command -v tput >/dev/null 2>&1 && [[ -t 1 ]]; then
  RED="$(tput setaf 1)"; GREEN="$(tput setaf 2)"
  YELLOW="$(tput setaf 3)"; NC="$(tput sgr0)"
else
  RED=''; GREEN=''; YELLOW=''; NC=''
fi
log()   { printf '%b\n' "${GREEN}[INFO]${NC} $*"; }
warn()  { printf '%b\n' "${YELLOW}[WARN]${NC} $*"; }
error() { printf '%b\n' "${RED}[ERROR]${NC} $*" >&2; }

###############################################################################
# 🛠️  共通ユーティリティ
###############################################################################
needs() {
  command -v "$1" >/dev/null 2>&1 || {
    error "'$1' が見つかりません。インストールしてください。"
    exit 1; }
}

run() {
  log "実行: $*"
  "$@" || warn "'$*' が非ゼロ終了しました（続行）"
}

trap 'error "想定外のエラーで終了 (#$LINENO)"; exit 1' ERR

###############################################################################
# 🧹  1) クリーンアップ
###############################################################################
cleanup() {
  log "Minikubeの権限を修正"
  run sudo chown -R "$USER" "$HOME/.minikube"
  run chmod -R u+wrx "$HOME/.minikube"

  log "クリーンアップを開始"
  [[ -f $DEPLOYMENT_FILE ]] \
    && run kubectl delete -f "$DEPLOYMENT_FILE" --ignore-not-found

  run kubectl delete secret ecr-registry-secret \
      --namespace "$NAMESPACE" --ignore-not-found
  run kubectl delete namespace "$NAMESPACE" --ignore-not-found

  if minikube profile list | grep -q "$CLUSTER_NAME"; then
    run minikube delete --profile "$CLUSTER_NAME"
  else
    log "Minikube クラスター '$CLUSTER_NAME' は存在しません"
  fi
  log "クリーンアップ完了"
}

###############################################################################
# 🚜  2) クラスター起動
###############################################################################
start_cluster() {
  log "Minikube クラスターを起動"
  local args=(
    start
    --profile "$CLUSTER_NAME"
    --driver "$MINIKUBE_DRIVER"
    --cpus "$MINIKUBE_CPUS"
    --memory "$MINIKUBE_MEMORY"
    --disk-size "$MINIKUBE_DISK_SIZE"
    --cache-images
    --disable-optimizations  # 不要なアドオンを無効化して起動を高速化
  )
  [[ -n $CONTAINER_RUNTIME ]] && args+=(--container-runtime "$CONTAINER_RUNTIME")
  run minikube "${args[@]}"

  # containerd の場合、docker-env は不要
  if minikube -p "$CLUSTER_NAME" docker-env >/dev/null 2>&1; then
    eval "$(minikube -p "$CLUSTER_NAME" docker-env)"
    log "docker-env を適用しました"
  else
    warn "containerd ランタイムのため docker-env をスキップ"
  fi
  log "クラスター起動完了"
}

###############################################################################
# ✨  3) 名前空間 & ECR シークレット
###############################################################################
setup_namespace() {
  log "名前空間 '$NAMESPACE' を作成"
  kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || \
    run kubectl create namespace "$NAMESPACE"
  # run kubectl config set-context --current --namespace="$NAMESPACE"
}

setup_ecr_auth() {
  log "ECR 認証をセットアップ"
  local pw
  pw="$(aws ecr get-login-password --region "$AWS_REGION")"
  echo "$pw" | docker login --username AWS --password-stdin "$ECR_REGISTRY"

  # --dry-run=client + -o yaml にすれば apply で idempotent にできる
  kubectl delete secret ecr-registry-secret \
      --namespace "$NAMESPACE" --ignore-not-found
  run kubectl create secret docker-registry ecr-registry-secret \
    --docker-server="$ECR_REGISTRY" \
    --docker-username=AWS \
    --docker-password="$pw" \
    --namespace="$NAMESPACE"
}

###############################################################################
# 🔍  4) 確認表示
###############################################################################
verify() {
  log "設定状態を確認"
  kubectl config current-context
  kubectl cluster-info
  kubectl get ns
  kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}'; echo
}

###############################################################################
# 🎛️  CLI オプション
###############################################################################
while [[ $# -gt 0 ]]; do
  case "$1" in
    --driver)          MINIKUBE_DRIVER="$2"; shift 2 ;;
    --containerd)      CONTAINER_RUNTIME="containerd"; shift ;;
    --runtime)         CONTAINER_RUNTIME="$2"; shift 2 ;;
    --cpus)            MINIKUBE_CPUS="$2"; shift 2 ;;
    --memory)          MINIKUBE_MEMORY="$2"; shift 2 ;;
    --disk-size)       MINIKUBE_DISK_SIZE="$2"; shift 2 ;;
    --help|-h)
      cat <<EOF
usage: $(basename "$0") [options]

--driver <docker|kvm2|...>     Minikube ドライバ（既定: docker）
--runtime <docker|containerd>  コンテナランタイム
--containerd                   同上（ショートカット）
--cpus <number>               Minikube に割り当てる CPU コア数（既定: 8）
--memory <number>             Minikube に割り当てるメモリ量（MiB単位、既定: 10000）
--disk-size <number>          Minikube のディスクサイズ（MiB単位、既定: 20000）
EOF
      exit 0
      ;;
    *) error "未知のオプション: $1"; exit 1 ;;
  esac
done

###############################################################################
# 🚀  メイン処理
###############################################################################
main() {
  for cmd in minikube kubectl aws docker; do needs "$cmd"; done

  log "=== Minikube リセットスクリプト開始 ==="
  cleanup
  start_cluster
  # setup_namespace
  # setup_ecr_auth
  verify
  log "=== スクリプト完了 🎉 ==="
}

main "$@"
