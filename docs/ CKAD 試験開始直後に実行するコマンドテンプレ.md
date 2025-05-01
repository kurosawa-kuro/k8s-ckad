# kubectl のショートカットを定義（aliasはリセットされる可能性あり）
export K=kubectl

# namespace の確認と切り替え（問題によって指定あり）
echo "=== Available namespaces ==="
kubectl get ns

# 出題で指定される namespace に切り替え（例：`team-a`）
# 問題指示に従って都度変更
kubectl config set-context --current --namespace=team-a

# 試験中によく使う manifest テンプレートファイルを準備
# 例：empty-pod.yaml の雛形
cat <<EOF > pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: sample
spec:
  containers:
  - name: app
    image: nginx
EOF

# よく使うショートカットも一時的にalias化（再起動時消えるので注意）
alias k=kubectl
