#!/usr/bin/env bash
set -euo pipefail

SERVER_IP="192.168.56.110"
NODE_IP="192.168.56.111"

export DEBIAN_FRONTEND=noninteractive

apt-get update -qq
apt-get install -y -qq curl

curl -fsSL https://get.k3s.io -o /tmp/k3s-install.sh
chmod +x /tmp/k3s-install.sh

K3S_URL=https://${SERVER_IP}:6443 \
K3S_TOKEN="${K3S_TOKEN}" \
INSTALL_K3S_EXEC="agent --node-ip ${NODE_IP}" \
/tmp/k3s-install.sh
