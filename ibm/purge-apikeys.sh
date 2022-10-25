#!/bin/bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

source ${SCRIPT_DIR}/_common_functions.sh

NAME_PATTERN="$1"

if [[ -z "${NAME_PATTERN}" ]]; then
  echo "The name or regex pattern of the apikey should be provided as the first argument" >&2
  exit 1
fi

check_prereqs || exit 1




ibmcloud iam api-keys --output JSON 2> /dev/null | \
jq --arg NAME "${NAME_PATTERN}" -r '.[] | select(.name | test($NAME)) | .id' | \
while read apikey_id; 
do
    ibmcloud iam api-key-delete "${apikey_id}" -f
done