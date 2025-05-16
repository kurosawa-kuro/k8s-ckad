# Minikube リソース設定
MINIKUBE_CPUS ?= 8
MINIKUBE_MEMORY ?= 10000
MINIKUBE_DISK_SIZE ?= 20000

# 基本リセット（最適化設定付き）
reset-hard:
	MINIKUBE_CPUS=$(MINIKUBE_CPUS) \
	MINIKUBE_MEMORY=$(MINIKUBE_MEMORY) \
	MINIKUBE_DISK_SIZE=$(MINIKUBE_DISK_SIZE) \
	./reset-hard.sh

# 軽量リセット（最小リソース設定）
reset-light:
	MINIKUBE_CPUS=4 \
	MINIKUBE_MEMORY=6000 \
	MINIKUBE_DISK_SIZE=15000 \
	./reset-hard.sh

# 高負荷用リセット（最大リソース設定）
reset-heavy:
	MINIKUBE_CPUS=12 \
	MINIKUBE_MEMORY=16000 \
	MINIKUBE_DISK_SIZE=30000 \
	./reset-hard.sh

reset-soft:
	./reset-soft.sh

ingress:
	./ingress.sh

# Minikube キャッシュ設定
cache-enable:
	minikube config set cache true

cache-add:
	@echo "よく使うイメージをキャッシュに追加します..."
	minikube cache add nginx:1.27-alpine
	minikube cache add haproxy:alpine
	minikube cache add busybox:latest

help:
	@echo "Available commands:"
	@echo "  make reset-hard    - 最適化設定で環境をリセット"
	@echo "  make reset-light   - 最小リソース設定で環境をリセット"
	@echo "  make reset-heavy   - 最大リソース設定で環境をリセット"
	@echo "  make reset-soft    - ソフトリセット（既存設定維持）"
	@echo "  make ingress       - Ingress Controller をインストール"
	@echo "  make cache-enable  - Minikube イメージキャッシュを有効化"
	@echo "  make cache-add     - よく使うイメージをキャッシュに追加"
	@echo "  make help          - このヘルプメッセージを表示"
	@echo ""
	@echo "リソース設定（環境変数で上書き可能）:"
	@echo "  MINIKUBE_CPUS=$(MINIKUBE_CPUS)        - CPU コア数"
	@echo "  MINIKUBE_MEMORY=$(MINIKUBE_MEMORY)    - メモリ量（MiB）"
	@echo "  MINIKUBE_DISK_SIZE=$(MINIKUBE_DISK_SIZE) - ディスクサイズ（MiB）"