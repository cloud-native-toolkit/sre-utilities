#!/bin/bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

source ${SCRIPT_DIR}/_common_functions.sh

NAME_PATTERN="$1"
ALL_REGIONS="$2"

if [[ -z "${NAME_PATTERN}" ]]; then
  echo "The name or regex pattern of the resource groups should be provided as the first argument" >&2
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
    ibmcloud target -r "${region}" 1> /dev/null

    echo "Finding volumes in region (${region}) for resource group name pattern: ${NAME_PATTERN}"
  fi

  ibmcloud is volumes --output json 2> /dev/null | \
    jq --arg NAME "${NAME_PATTERN}" -r '.[] | select(.resource_group.name | test($NAME)) | .id' | \
    while read volume_id; 
  do
    delete_volume "${volume_id}"
  done
done

if [[ -n "${CURRENT_REGION}" ]]; then
  ibmcloud target -r "${CURRENT_REGION}" 1> /dev/null 2> /dev/null
fi
