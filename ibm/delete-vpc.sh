#!/bin/bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

source ${SCRIPT_DIR}/_common_functions.sh

NAME_PATTERN="$1"
ALL_REGIONS="$2"

if [[ -z "${NAME_PATTERN}" ]]; then
  echo "The name or regex pattern of the VPC(s) should be provided as the first argument" >&2
  return 1
fi

check_prereqs || exit 1

CURRENT_REGION=$(ibmcloud target --output json | jq -r '.region.name // empty')

if [[ -n "${ALL_REGIONS}" ]] || [[ -z "${CURRENT_REGION}" ]]; then
  REGIONS=$(ibmcloud regions --output json | jq -r '.[] | .Name')
else
  REGIONS="${CURRENT_REGION}"
fi

echo "${REGIONS}" | while read region; do
  
  if [[ "${region}" != "${CURRENT_REGION}" ]]; then
    ibmcloud target -r "${region}" 1> /dev/null || continue

    echo "Finding VPCs in region: ${region}"
  fi

  ibmcloud is vpcs --output json 2> /dev/null | \
    jq --arg NAME "${NAME_PATTERN}" -r '.[] | select(.name | test($NAME)) | .name' | \
    while read vpc_name; 
  do
    delete_vpc "${vpc_name}"
  done
done

if [[ -n "${CURRENT_REGION}" ]]; then
  ibmcloud target -r "${CURRENT_REGION}" 1> /dev/null 2> /dev/null
fi
