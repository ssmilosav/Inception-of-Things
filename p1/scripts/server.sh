#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq curl

curl -fL https://get.k3s.io -o /tmp/k3s-install.sh
chmod +x /tmp/k3s-install.sh

K3S_TOKEN="${K3S_TOKEN}" \
INSTALL_K3S_EXEC="server --node-ip 192.168.56.110 --write-kubeconfig-mode 644" \
/tmp/k3s-install.sh > /var/log/k3s-install.log 2>&1

echo "k3s server installed"
