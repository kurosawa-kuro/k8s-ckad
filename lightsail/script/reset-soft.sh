#!/usr/bin/env bash
set -Eeuo pipefail; IFS=$'\n\t'
KEEP_NS='^(kube-|default$|local-path-storage$)'
log(){ printf '\033[32m[INFO]\033[0m %s\n' "$*"; }

###############################################################################
# 1) Namespaced リソース
###############################################################################
log "▶ wipe user namespaces..."
for ns in $(kubectl get ns -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
  [[ $ns =~ $KEEP_NS ]] && continue
  kubectl delete ns "$ns" --wait=false
done

###############################################################################
# 2) Cluster-scoped リソース
###############################################################################
log "▶ delete cluster-scoped *user* resources..."

KEEP_CLUSTER='^(nodes(\.|$)|namespaces(\.|$)|customresourcedefinitions(\.|$)|'
KEEP_CLUSTER+='storageclasses(\.|$)|csidrivers(\.|$)|'
KEEP_CLUSTER+='clusterrolebindings(\.|$)|clusterroles(\.|$)|'
KEEP_CLUSTER+='apiservices(\.|$)|flowschemas(\.|$)|prioritylevelconfigurations(\.|$)|'
KEEP_CLUSTER+='componentstatuses(\.|$))'

kubectl api-resources --verbs=list --namespaced=false -o name \
| grep -Ev "$KEEP_CLUSTER" \
| xargs -r -n1 kubectl delete --all --wait=false --ignore-not-found

log "✅ safe-wipe completed (≈10 s)"
