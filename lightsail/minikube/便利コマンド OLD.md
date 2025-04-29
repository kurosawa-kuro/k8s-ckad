了解！`kubectl run` を組み込んだ完全対応版にアップデートしたよ💪  
CKADに必要な全カテゴリを網羅しつつ、**試験でも実務でも超使える構成**です👇

kubectl api-resouces
kubectl --help
kubectl rollout restart deploy

---

# ✅ CKAD試験カテゴリ別 `kubectl` コマンド一覧（完全版）

---

## 🧱 **Pod / Deployment / ReplicaSet / DaemonSet / Job**

| 操作 | コマンド例 |
|------|------------|
| Pod一覧 | `kubectl get pods`  
| Pod作成テンプレ生成 | `kubectl run mypod --image=nginx --restart=Never --dry-run=client -o yaml > pod.yaml`  
| 一時Pod起動（対話用） | `kubectl run debug --image=busybox --rm -it --restart=Never -- sh`  
| Deployment作成 | `kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > dep.yaml`  
| Deployment確認 | `kubectl get deployment`, `kubectl describe deployment nginx`  
| Job作成 | `kubectl create job test-job --image=busybox --dry-run=client -o yaml > job.yaml`  
| CronJob作成 | `kubectl create cronjob test-cron --image=busybox --schedule="*/1 * * * *" --dry-run=client -o yaml > cron.yaml`  
| ログ確認 | `kubectl logs <pod-name>`  
| describe確認 | `kubectl describe pod <pod-name>`  
| リソース削除 | `kubectl delete -f <file>.yaml`  

---

## 🌐 **Service / Network / Ingress**

| 操作 | コマンド例 |
|------|------------|
| Service一覧 | `kubectl get svc`  
| Service作成 | `kubectl expose deployment nginx --port=80 --target-port=80 --type=ClusterIP --dry-run=client -o yaml > svc.yaml`  
| Ingress作成 | `kubectl create ingress nginx-ingress --rule="/=nginx-service:80" --dry-run=client -o yaml > ingress.yaml`  
| ポートフォワード | `kubectl port-forward svc/nginx-service 8080:80`  
| 一時Podでcurl確認 | `kubectl run curltest --image=curlimages/curl -it --rm --restart=Never -- sh`  

---

## ⚙️ **ConfigMap / Secret**

| 操作 | コマンド例 |
|------|------------|
| ConfigMap作成 | `kubectl create configmap my-config --from-literal=key=value --dry-run=client -o yaml > cm.yaml`  
| Secret作成 | `kubectl create secret generic my-secret --from-literal=password=1234 --dry-run=client -o yaml > secret.yaml`  
| ConfigMap確認 | `kubectl get configmap`, `kubectl describe configmap <name>`  

---

## 🧪 **Probes / Resource Limits**

| 操作 | コマンド例 |
|------|------------|
| readinessProbe / livenessProbe 追加 | YAML編集で追加：`httpGet`, `initialDelaySeconds`, `periodSeconds`  
| リソース制限の追加 | `resources.requests.cpu`, `resources.limits.memory` など YAML編集  

---

## 🗂 **Namespace / Context**

| 操作 | コマンド例 |
|------|------------|
| Namespace一覧 | `kubectl get ns`  
| Namespace切り替え | `kubectl config set-context --current --namespace=<name>`  
| 現在のNamespace確認 | `kubectl config view --minify | grep namespace`  

---

## 🧰 **状態確認 / トラブル対応**

| 操作 | コマンド例 |
|------|------------|
| リソース一覧 | `kubectl get all`  
| イベント確認 | `kubectl get events`  
| describe確認 | `kubectl describe <kind> <name>`  
| ログ確認 | `kubectl logs <pod>`  
| 再適用 | `kubectl apply -f file.yaml`  

---

## 💥 **やり直し・リセット用**

| 操作 | コマンド例 |
|------|------------|
| 単体削除 | `kubectl delete pod <name>`  
| 全削除 | `kubectl delete all --all`  
| ファイル差し替え | `vim xxx.yaml` → `kubectl apply -f xxx.yaml`  
| 一時テストPod起動 | `kubectl run tmp --image=busybox --rm -it --restart=Never -- sh`  

---

## 📄 **テンプレ生成系（--dry-run）**

| 対象 | コマンド |
|------|----------|
| Pod | `kubectl run mypod --image=nginx --restart=Never --dry-run=client -o yaml`  
| Deployment | `kubectl create deployment nginx --image=nginx --dry-run=client -o yaml`  
| Job | `kubectl create job myjob --image=busybox --dry-run=client -o yaml`  
| CronJob | `kubectl create cronjob mycron --image=busybox --schedule="*/1 * * * *" --dry-run=client -o yaml`  
| Service | `kubectl expose deployment nginx --port=80 --target-port=80 --dry-run=client -o yaml`  
| Ingress | `kubectl create ingress nginx-ingress --rule="/=nginx-service:80" --dry-run=client -o yaml`  

---

## 🎯 おすすめエイリアス（設定しておくと快適）

```bash
alias k="kubectl"
alias kc="kubectl create"
alias ka="kubectl apply -f"
alias kr="kubectl replace --force -f"
alias kn="kubectl config set-context --current --namespace"
alias debug="kubectl run -it --rm --image=curlimages/curl c -- sh"
```

---

この最新版、PDF・Markdown・印刷用いずれも対応できるよ📄  
必要なら `/docs` に落とすし、VSCode用チートパネルとしても整形OK👌  
続けて `ConfigMap + envFrom` or `readinessProbe` やってく？🔥