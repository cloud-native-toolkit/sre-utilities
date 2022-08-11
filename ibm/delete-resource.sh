#!/bin/bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

source ${SCRIPT_DIR}/_common_functions.sh

NAME_PATTERN="$1"

if [[ -z "${NAME_PATTERN}" ]]; then
  echo "The name or regex pattern of the VPC(s) should be provided as the first argument" >&2
  return 1
fi

check_prereqs || exit 1

ibmcloud resource service-instances --output json | \
  jq --arg NAME "${NAME_PATTERN}" -r '.[] | select(.name | test($NAME)) | .name' | \
  while read name; 
do
  delete_resource "${name}"
done
