cd /home/wsl/dev/k8s-ckad/wsl/script
make reset-heavy
cd /home/wsl/dev/k8s-ckad/wsl/test

alias k=kubectl
export do="--dry-run=client -o yaml"
kubectl config set-context --current --help | grep -A3 -B3 -- --namespace
alias kn='kubectl config set-context --current --namespace '
alias kcfg='kubectl get cm,secret,sa,role,pvc,svc,events -n'

kubectl apply -f -setup-doc-bootstrap-namespaces.yaml