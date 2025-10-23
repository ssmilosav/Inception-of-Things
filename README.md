# Inception-of-Things - 42 project - DevOps lab

## 🧭 Overview
Hands-on DevOps lab inside **virtual machines** (as required by the subject). Each part adds a skill: VM automation, cluster basics, routing, scaling, then Git-driven deployments.

## 🚦 Status
- 🟢 **Part 1** - Vagrantfile (2 VMs) + small K3s cluster *(done)*
- 🟢 **Part 2** - 3 web apps behind host-based routing *(done)* 
- 🟠 **Part 3** - K3d + Argo CD (GitOps) *(currently working on)*

## 🧩 Part 1 - K3s and Vagrant

**What I built** \
A reproducible 2-node K3s cluster on VirtualBox using a single `Vagrantfile`:
- Server `192.168.56.110` (control plane) exports the join token
- Worker `192.168.56.111` joins via K3S_URL + token
- Host-only networking, synced `/vagrant` for token handoff

**Concepts covered** \
Vagrant multi-machine · private networks · provisioning · K3s server/agent · secure join · kubeconfig permissions

## ▶️ Run
```
# from repo root
cd p1
vagrant up
```

## 🔎 Quick checks
**From the host** (non-interactive):
```
# NIC/IPs (expect .110 on server, .111 on worker)
vagrant ssh smilosavS  -c "hostname && ip -4 a show eth1"
vagrant ssh smilosavSW -c "hostname && ip -4 a show eth1"

# Service state
vagrant ssh smilosavS  -c "systemctl is-active k3s"
vagrant ssh smilosavSW -c "systemctl is-active k3s-agent"

# Cluster health (no sudo needed thanks to 644 kubeconfig)
vagrant ssh smilosavS -c 'KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl get nodes -o wide'
```
**Inside a VM** (interactive):
```
ip -4 a show eth1
systemctl is-active k3s          # on server
systemctl is-active k3s-agent    # on worker
KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl get nodes -o wide   # on server
```

## 🧯 Troubleshooting (common hiccups)
= **“connection reset / disconnect” during first `vagrant up`** \
Normal key-swap/startup behavior. Wait it out; only act if it errors.

= **No host-only IP on eth1** \
`vagrant reload`, then check: `ip -4 a show eth1`. Expect .110/.111 on eth1.

= **Nodes not Ready** \
Confirm services: `systemctl is-active k3s` / `k3s-agent`. \
Logs: `sudo journalctl -u k3s[-agent] -n 50 --no-pager`. \
Verify agent join args (correct `K3S_URL` and token).

= **kubectl asks for root** \
Ensure server was installed with `--write-kubeconfig-mode 644`; use
`KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl …`.

## 🧩 Part 2 - Ingress routing & scaling (k3s + Traefik)

**What I built** \
One k3s node serving three web apps via host-based routing with Traefik (k3s’s default ingress controller).
- `app1.com` → app1 (single replica)
- `app2.com` → app2 (3 replicas, to show load distribution)
- Any other host → app3 (acts as the default site)

All apps use `paulbouwer/hello-kubernetes:1.10` with distinct `MESSAGE`s.

**Concepts covered** \
Deployments · Services (ClusterIP) · Ingress + `ingressClassName: traefik` · default backend · replicas & rollout

## ▶️ Run
```
cd p2
vagrant up
# Apply manifests on the node
vagrant ssh smilosavS -c 'KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl apply -f /vagrant/confs'

```

## 🔁 Vagrant lifecycle
```
vagrant status
vagrant ssh NAME
vagrant ssh NAME -c "CMD"

vagrant reload [NAME]          # apply Vagrantfile changes (reboot)
vagrant provision [NAME]       # re-run provisioners (no reboot)
vagrant up --provision [NAME]  # boot + run provisioners

vagrant halt [NAME]            # clean shutdown
vagrant suspend [NAME]         # save RAM state
vagrant resume [NAME]          # resume from suspend
vagrant destroy -f [NAME]      # remove VM

vagrant port [NAME]            # forwarded ports
vagrant global-status --prune  # clean stale entries
```

## 📚 Resources (official)
- Vagrant — Getting started / Multi-machine / Private networks / Shell provisioning / Synced folders
https://developer.hashicorp.com/vagrant

- K3s — Installation / Architecture
https://docs.k3s.io

- Kubernetes — kubectl install / Cheat sheet
https://kubernetes.io/docs/home/