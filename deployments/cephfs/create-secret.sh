#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 4 ]]; then
  echo "Usage: $0 <ceph-user-id> <key-file> [namespace] [secret-name]" >&2
  exit 1
fi

user_id=$1
key_file=$2
namespace=${3:-ceph-csi-operator-system}
secret_name=${4:-cephfs-csi-secret}

if [[ -z $user_id || $user_id == client.* || $user_id == *$'\n'* ]]; then
  echo 'Specify a Ceph user ID without the client. prefix or a newline.' >&2
  exit 1
fi
if [[ ! -f $key_file || ! -r $key_file ]]; then
  echo 'Key file does not exist or is not readable.' >&2
  exit 1
fi

umask 077
tmp_dir=$(mktemp -d)
trap 'rm -rf -- "$tmp_dir"' EXIT
printf '%s' "$user_id" > "$tmp_dir/userID"
python3 - "$key_file" "$tmp_dir/userKey" <<'PY'
import base64
import binascii
import pathlib
import sys

try:
    key = pathlib.Path(sys.argv[1]).read_bytes().strip()
    if not key:
        raise ValueError('empty key')
    base64.b64decode(key, validate=True)
    pathlib.Path(sys.argv[2]).write_bytes(key)
except (OSError, ValueError, binascii.Error):
    print('The key file must contain a valid, non-empty CephX base64 key.', file=sys.stderr)
    sys.exit(1)
PY

kubectl -n "$namespace" create secret generic "$secret_name" \
  --from-file="userID=$tmp_dir/userID" \
  --from-file="userKey=$tmp_dir/userKey"
