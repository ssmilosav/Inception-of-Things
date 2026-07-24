#!/usr/bin/env bash
set -euo pipefail

SERVER_IP="192.168.56.110"

export DEBIAN_FRONTEND=noninteractive

apt-get update -qq
apt-get install -y -qq curl

curl -fsSL https://get.k3s.io -o /tmp/k3s-install.sh
chmod +x /tmp/k3s-install.sh

K3S_TOKEN="${K3S_TOKEN}" \
INSTALL_K3S_EXEC="server --node-ip ${SERVER_IP} --flannel-iface eth1 --write-kubeconfig-mode 644" \
/tmp/k3s-install.sh

echo "DONE: k3s server installed"
