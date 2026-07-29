#!/usr/bin/env bash
set -euo pipefail

CONFS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../confs" && pwd)"

echo "== Installing tools =="
if ! command -v docker >/dev/null 2>&1; then
    echo "=== Installing docker... ==="
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER" || true
fi

if ! command -v kubectl >/dev/null 2>&1; then
    echo "=== Installing kubectl... ==="
    curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm -f kubectl
fi

if ! command -v k3d >/dev/null 2>&1; then
    echo "=== Installing k3d... ==="
    curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi


echo "== Create the iot cluster =="
if ! k3d cluster list 2>/dev/null | grep -q "^iot\b"; then
    k3d cluster create "iot"
fi

echo "== Create namespaces (argocd, dev) =="
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev    --dry-run=client -o yaml | kubectl apply -f -

echo "== Installing Argo CD =="
kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "== Waiting for Argo CD to be ready... =="
kubectl rollout status deployment/argocd-server                  -n argocd --timeout=600s
kubectl rollout status deployment/argocd-repo-server             -n argocd --timeout=600s
kubectl rollout status statefulset/argocd-application-controller -n argocd --timeout=600s

echo "== Applying the Argo CD application =="
kubectl apply -f "${CONFS_DIR}/application.yaml"

echo "DONE: Argo CD installed =="
echo "admin password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
echo "UI:  kubectl port-forward svc/argocd-server -n argocd 8080:443   -> https://localhost:8080 (user: admin)"
echo "app: kubectl port-forward svc/playground   -n dev    8888:8888   -> curl http://localhost:8888/"