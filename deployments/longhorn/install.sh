#!/usr/bin/env bash
set -euo pipefail

helm repo add longhorn https://charts.longhorn.io
helm repo update longhorn

helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --version 1.13.0 \
  --set defaultSettings.defaultDataPath=/data/longhorn \
  --wait
