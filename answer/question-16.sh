helm repo add bitnami https://charts.bitnami.com/bitnami

helm search repo bitnami/nginx

helm install my-nginx bitnami/nginx --create-namespace -n ckad-helm

helm list -n ckad-helm

helm upgrade my-nginx bitnami/nginx -n ckad-helm --set replicaCount=2
