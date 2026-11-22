#!/usr/bin/env bash
set -euo pipefail

helm install cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.21.3 \
  --set crds.enabled=true \
  --wait
