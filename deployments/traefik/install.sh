#!/usr/bin/env bash
set -euo pipefail

helm repo add traefik https://traefik.github.io/charts
helm repo update traefik

helm install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --version 42.4.1 \
  --set service.type=LoadBalancer \
  --wait
