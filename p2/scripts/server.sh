#!/usr/bin/env bash

curl -sfL https://get.k3s.io | \
    INSTALL_K3S_EXEC="server --node-ip 192.168.56.110 --write-kubeconfig-mode 644" \
    sh -