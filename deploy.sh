#!/usr/bin/env bash
set -euo pipefail

action=""
kubeversion=""
new_nodes=""
del_nodes=""
inventory="inventory.ini"

export yellow=$'\e[33;01m'
export green=$'\e[32;01m'
export reset=$'\e[0m'
cd "$(dirname "$0")"

function deploy()
{
  mkdir -p .ansible/facts
  local -a version_args=()
  if [[ -n ${kubeversion} ]]; then
    version_args=(-e "kube_version=${kubeversion}")
  fi
  if [[ ${action} == "install" ]];
  then
    ansible-playbook -i "$inventory" "${playbook_run}" --become -e "action_runner=${action}" "${version_args[@]}"
  
  elif [[ ${action} == "addmember" ]]; then
    mkdir -p .ansible/facts
    ansible-playbook -i "$inventory" ./vendor/kubespray/playbooks/facts.yml --become
    ansible-playbook -i "$inventory" "${playbook_run}" --become \
      -l "${new_nodes}" \
      -e "action_runner=${action} new_nodes=${new_nodes}" "${version_args[@]}"

  elif [[ ${action} == "remove" ]]; then
    mkdir -p .ansible/facts
    ansible-playbook -i "$inventory" ./vendor/kubespray/playbooks/facts.yml --become
    #kubectl cordon ${del_nodes}
    #kubectl drain ${del_nodes} --ignore-daemonsets --delete-emptydir-data --grace-period=60 --timeout=10m

    ansible-playbook -i "$inventory" "${playbook_run}" --become \
      -l "${del_nodes}" \
      -e "action_runner=${action} node=${del_nodes} reset_nodes=true allow_ungraceful_removal=false" "${version_args[@]}"
  fi


  echo -e "${green} Running playbook for action: ${action}${reset}"

  }

function main()
{
  if [[ ! -x .venv/bin/ansible-playbook ]]; then
    echo "Virtual environment not found. Run ./setup-local.sh." >&2
    exit 1
  fi
  export PATH="$PWD/.venv/bin:$PATH"
  ansible --version
  deploy
}

#------------------------
# Get Params
#------------------------
if (( $# == 0 )); then
  echo "No arguments provided." >&2
fi

for arg in "$@"
do
  case ${arg} in
    --action=* )
      export action=${arg##*=}
      ;;
    --inventory=* )
      inventory=${arg#*=}
      ;;
    --kubeversion=* )
      export kubeversion=${arg##*=}
      ;; 
    --new_nodes=* )
      export new_nodes=${arg##*=}
      ;;
    --del_nodes=* )
      export del_nodes=${arg##*=}
      ;;
    * )
      echo "Unknown argument: ${arg}" >&2
      exit 1
      ;;            
  esac
done

#------------------------
# Main
#------------------------
if [[ ${action} =~ ^(install|addmember|remove)$ ]] 
then
  export playbook_run="cluster.yml" 
else
  echo "Usage: $0 --action=<install|addmember|remove> [--inventory=<file>] [--kubeversion=<version without v>] [--new_nodes=<nodes>] [--del_nodes=<nodes>]" >&2 
  exit 1
fi

if [[ ${kubeversion} == v* ]]; then
  echo "Specify --kubeversion without the v prefix." >&2
  exit 1
fi
if [[ ! -f ${inventory} ]]; then
  echo "Inventory not found: ${inventory}" >&2
  exit 1
fi
if [[ ${action} == addmember && -z ${new_nodes} ]]; then
  echo "Specify --new_nodes to add nodes." >&2
  exit 1
fi
if [[ ${action} == remove && -z ${del_nodes} ]]; then
  echo "Specify --del_nodes to remove nodes." >&2
  exit 1
fi

main "$@"
