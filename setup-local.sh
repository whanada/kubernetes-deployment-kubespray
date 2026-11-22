#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v python3 >/dev/null; then
  echo 'Python 3 is required to create the virtual environment.' >&2
  exit 1
fi
if [[ ! -f vendor/kubespray/requirements.txt ]]; then
  echo 'Initializing the Kubespray submodule...'
  git submodule update --init --recursive
  if [[ ! -f vendor/kubespray/requirements.txt ]]; then
    echo 'Could not find vendor/kubespray/requirements.txt.' >&2
    exit 1
  fi
fi
python3 -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r vendor/kubespray/requirements.txt
printf '\nEnvironment ready. Activate it with: source .venv/bin/activate\n'
