../script/reset.sh 


kubectl explain pod --recursive | less


kubectl run test --image=busybox --dry-run=client -o yaml --command -- sleep 3600 > pod.yaml

試験中ネームスペース切り替えコマンドを忘れた
explain helpで探す方法を教えて
kubectl config set-context --current --namespace=

関係図

namespace ← config
containers ← spec
volumeMounts ← containers
volumes ← spec
ConfigMap ← kind