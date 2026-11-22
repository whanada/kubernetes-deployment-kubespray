#!/usr/bin/env bash
set -euo pipefail

# Install a new Ceph-CSI Operator. Do not run when Rook manages Ceph-CSI.
kubectl create -f https://raw.githubusercontent.com/ceph/ceph-csi-operator/v1.1.0/deploy/all-in-one/install.yaml
kubectl -n ceph-csi-operator-system rollout status deployment/ceph-csi-operator-controller-manager --timeout=5m
