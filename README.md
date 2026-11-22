# Cluster Provisioner

Deploy a Kubernetes cluster with Kubespray v2.32.0 from your local machine.

## Requirements

- Git and Python 3 with `venv` and `pip`
- Network access to install Python packages and SSH access to all cluster nodes
- A remote user with sudo privileges

## Deploy

1. Clone the repository and prepare the local environment:

   ```bash
   git clone --recurse-submodules https://github.com/whanada/kubernetes-deployment-kubespray.git
   cd kubernetes-deployment-kubespray
   ./setup-local.sh
   ```

2. Edit `inventory.ini`: configure the nodes, SSH user and key, Kubernetes version, network plugin, subnets and VIP settings. Choose a Kubernetes version supported by Kubespray 2.32, such as `1.36.4`.

3. Deploy the cluster:

   ```bash
   ./deploy.sh --action=install
   ```

   To use another inventory, add `--inventory=path/to/inventory.ini`.

The setup creates a local `.venv`; it is excluded from Git. Validate your inventory and deployment in a test environment before using it in production.

## Optional components

See [deployments/README.md](deployments/README.md) for cert-manager, Traefik, Longhorn and CephFS setup.

## Kubespray license

This project uses [Kubespray](https://github.com/kubernetes-sigs/kubespray) as a Git submodule. Kubespray is licensed under the [Apache License 2.0](https://github.com/kubernetes-sigs/kubespray/blob/v2.32.0/LICENSE).
