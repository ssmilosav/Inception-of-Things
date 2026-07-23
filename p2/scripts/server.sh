#!/usr/bin/env bash

set -euo pipefail

SERVER_IP="192.168.56.110"

export DEBIAN_FRONTEND=noninteractive

apt-get update -qq
apt-get install -y -qq curl

curl -fsSL https://get.k3s.io -o /tmp/k3s-install.sh
chmod +x /tmp/k3s-install.sh

INSTALL_K3S_EXEC="server --node-ip ${SERVER_IP} --write-kubeconfig-mode 644" \
/tmp/k3s-install.sh

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

kubectl wait --for=condition=Ready node --all --timeout=180s

kubectl apply -f /vagrant/confs/

kubectl get all
kubectl get ingress