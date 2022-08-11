#!/bin/bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

source ${SCRIPT_DIR}/_common_functions.sh

NAME_PATTERN="$1"
PURGE_VOLUMES="$2"

if [[ -z "${NAME_PATTERN}" ]]; then
  echo "The name or regex pattern of the cluster(s) should be provided as the first argument" >&2
  return 1
fi

check_prereqs || exit 1

ibmcloud resource groups --output json | \
  jq --arg NAME "${NAME_PATTERN}" -r '.[] | select(.name | test($NAME)) | .name' | \
  while read rg_name; 
do
  if [[ -n "${PURGE_VOLUMES}" ]]; then
    ${SCRIPT_DIR}/purge-volumes.sh "${rg_name}" --all-regions
  fi

  ibmcloud resource group-delete -f "${rg_name}"
done
