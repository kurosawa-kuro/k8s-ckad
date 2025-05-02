#!/usr/bin/env bash
# reset-soft.sh : Minikube を残したまま “ユーザー作成リソース” だけ削除
set -Eeuo pipefail
IFS=$'\n\t'

KEEP_NS='^(kube-|default$|local-path-storage$)'
log(){ printf '\033[32m[INFO]\033[0m %s\n' "$*"; }

###############################################################################
# 1) Namespace-scoped ── ユーザー NS を一掃
###############################################################################
log "▶ wipe user namespaces..."
for ns in $(kubectl get ns -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
  [[ $ns =~ $KEEP_NS ]] && continue
  kubectl delete ns "$ns" --wait=false
done

###############################################################################
# 2) Cluster-scoped ── システム必須をホワイトリストで保護
###############################################################################
log "▶ delete cluster-scoped *user* resources..."

KEEP_CLUSTER='^(nodes?|namespaces?|customresourcedefinitions?|storageclasses?|csidrivers?|csinodes?|clusterrolebindings?|clusterroles?|apiservices?|flowschemas?|prioritylevelconfigurations?|certificatesigningrequests?|componentstatuses?)(\.|$)'

kubectl api-resources --verbs=list --namespaced=false -o name \
| grep -Ev "$KEEP_CLUSTER" \
| xargs -r -n1 kubectl delete --all --wait=false --ignore-not-found

log "✅ safe-wipe completed (≈10 s)"
