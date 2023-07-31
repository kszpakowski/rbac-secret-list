#!/bin/bash
APISERVER=https://homelab.com:6443
NS=rbac-secrets
SA=app-service-account
AS=app-secret
OS=other-secret

RED='\033[0;31m'
NC='\033[0m'

kubectl create ns $NS
kubectl -n $NS create sa $SA

TOKEN_NAME=$(kubectl -n $NS get serviceaccount $SA -o go-template --template='{{range .secrets}}{{.name}}{{"\n"}}{{end}}' | grep token)
TOKEN=$(kubectl -n $NS get secret $TOKEN_NAME -o go-template --template '{{index .data "token"}}' | base64 -d)

kubectl -n $NS create secret generic $AS --from-file files/app-secret.txt
kubectl -n $NS create secret generic $OS --from-file files/other-secret.txt

kubectl apply -f files/rbac.yaml
# curl -H "Accept: application/json" --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER}/openapi/v2 > api.json
RES=$(curl -H "Accept: application/json" --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER}/api/v1/namespaces/$NS/secrets)

ECHO $RES | grep app-secret.txt > /dev/null && printf "${RED}App Secret Found${NC}\n"

ECHO $RES | grep other-secret.txt > /dev/null && printf "${RED}Other Secret Found${NC}\n"

kubectl delete -f files/rbac.yaml


kubectl delete ns $NS