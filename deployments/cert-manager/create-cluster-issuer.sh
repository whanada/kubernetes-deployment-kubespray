#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <email> [staging|production]" >&2
  exit 1
fi
email=$1
environment=${2:-staging}
case "$environment" in
  staging) server=https://acme-staging-v02.api.letsencrypt.org/directory ;;
  production) server=https://acme-v02.api.letsencrypt.org/directory ;;
  *) echo 'Environment must be staging or production.' >&2; exit 1 ;;
esac

python3 - "$email" "$environment" "$server" <<'PY' | kubectl apply -f -
import json, sys
email, environment, server = sys.argv[1:]
name = f'letsencrypt-{environment}'
print(json.dumps({
    'apiVersion': 'cert-manager.io/v1', 'kind': 'ClusterIssuer',
    'metadata': {'name': name},
    'spec': {'acme': {'email': email, 'server': server,
        'privateKeySecretRef': {'name': name + '-account-key'},
        'solvers': [{'http01': {'ingress': {'ingressClassName': 'traefik'}}}]}},
}))
PY
