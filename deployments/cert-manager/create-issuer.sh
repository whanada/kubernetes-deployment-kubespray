#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 <email> <namespace> [staging|production]" >&2
  exit 1
fi
email=$1
namespace=$2
environment=${3:-staging}
case "$environment" in
  staging) server=https://acme-staging-v02.api.letsencrypt.org/directory ;;
  production) server=https://acme-v02.api.letsencrypt.org/directory ;;
  *) echo 'Environment must be staging or production.' >&2; exit 1 ;;
esac

python3 - "$email" "$namespace" "$environment" "$server" <<'PY' | kubectl apply -f -
import json, sys
email, namespace, environment, server = sys.argv[1:]
name = f'letsencrypt-{environment}'
print(json.dumps({
    'apiVersion': 'cert-manager.io/v1', 'kind': 'Issuer',
    'metadata': {'name': name, 'namespace': namespace},
    'spec': {'acme': {'email': email, 'server': server,
        'privateKeySecretRef': {'name': name + '-account-key'},
        'solvers': [{'http01': {'ingress': {'ingressClassName': 'traefik'}}}]}},
}))
PY
