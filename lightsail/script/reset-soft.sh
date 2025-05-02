#!/usr/bin/env bash
# reset-soft.sh : Minikube を残したままユーザーリソースを完全クリア
set -Eeuo pipefail
IFS=$'\n\t'

KEEP_NS_REGEX='^(kube-|default$|local-path-storage$)'   # ← default は残す
log(){ printf '\033[32m[INFO]\033[0m %s\n' "$*"; }

###############################################################################
# 1) default“以外”のユーザー NS を削除
###############################################################################
log "▶ wipe non-system, non-default namespaces..."
for ns in $(kubectl get ns -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
  [[ $ns =~ $KEEP_NS_REGEX ]] && continue
  kubectl delete ns "$ns" --wait=false
done

###############################################################################
# 2) default 名前空間を空にする
###############################################################################
log "▶ purge resources inside <default>..."
kubectl api-resources --verbs=list --namespaced -o name \
| xargs -r -n1 kubectl -n default delete --all --wait=false --ignore-not-found

###############################################################################
# 3) Cluster-scoped のユーザーリソースを削除
###############################################################################
log "▶ delete cluster-scoped *user* resources..."
KEEP_CLUSTER='^(nodes?|namespaces?|customresourcedefinitions?|storageclasses?|csidrivers?|csinodes?|clusterrolebindings?|clusterroles?|apiservices?|flowschemas?|prioritylevelconfigurations?|componentstatuses?)(\.|$)'
kubectl api-resources --verbs=list --namespaced=false -o name \
| grep -Ev "$KEEP_CLUSTER" \
| xargs -r -n1 kubectl delete --all --wait=false --ignore-not-found

log "✅ reset-soft completed (≈10 s)"
