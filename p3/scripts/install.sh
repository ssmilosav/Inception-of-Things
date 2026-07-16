#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="iot"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> [1/6] Checking / installing tools"

if ! command -v docker >/dev/null 2>&1; then
    echo "    installing docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER" || true
    echo "    NOTE: first-time Docker install — you may need to log out/in once, then re-run."
fi

if ! command -v kubectl >/dev/null 2>&1; then
    echo "    installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm -f kubectl
fi

if ! command -v k3d >/dev/null 2>&1; then
    echo "    installing k3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

echo "==> [2/6] Creating k3d cluster '${CLUSTER_NAME}'"
if k3d cluster list 2>/dev/null | grep -q "^${CLUSTER_NAME}\b"; then
    echo "    cluster already exists, skipping"
else
    k3d cluster create "${CLUSTER_NAME}"
fi

echo "==> [3/6] Creating namespaces (argocd, dev)"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev    --dry-run=client -o yaml | kubectl apply -f -

echo "==> [4/6] Installing Argo CD"
kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "==> [5/6] Waiting for Argo CD to be ready (can take a few minutes)..."
kubectl rollout status deployment/argocd-server                  -n argocd --timeout=600s
kubectl rollout status deployment/argocd-repo-server             -n argocd --timeout=600s
kubectl rollout status statefulset/argocd-application-controller -n argocd --timeout=600s

echo "==> [6/6] Applying the Argo CD Application"
kubectl apply -f "${SCRIPT_DIR}/../confs/application.yaml"

echo ""
echo "=========================================================="
echo " Argo CD installed. Initial admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" | base64 -d
echo ""
echo "=========================================================="
echo " Argo CD UI:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "   open https://localhost:8080   (user: admin)"
echo ""
echo " The app:"
echo "   kubectl port-forward svc/playground -n dev 8888:8888"
echo "   curl http://localhost:8888/"
echo "=========================================================="
