cd ~/dev/k8s-ckad/wsl/test
./setup/-setup.sh

cd ~/dev/k8s-ckad/wsl/test
./setup/-setup-alias.sh

alias k=kubectl
export do="--dry-run=client -o yaml"
kubectl config set-context --current --help | grep -A3 -B3 -- --namespace
alias kn='kubectl config set-context --current --namespace '