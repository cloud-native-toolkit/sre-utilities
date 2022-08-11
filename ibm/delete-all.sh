#!/bin/bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

source ${SCRIPT_DIR}/_common_functions.sh

usage() {
  echo "Deletes all resources (service resources and vpcs) that meet the provided regex pattern"
  echo ""
  echo "usage: delete-all.sh {NAME_PATTERN}"
  echo ""
  echo "where:"
  echo "  - NAME_PATTERN - is the regex pattern for the resource names"
}

NAME_PATTERN="$1"

if [[ -z "${NAME_PATTERN}" ]]; then
  usage
  exit 1
elif [[ "${NAME_PATTERN}" =~ ^-h|^--help ]]; then
  usage
  exit 0
fi

check_prereqs || exit 1

${SCRIPT_DIR}/delete-cluster.sh "${NAME_PATTERN}"
${SCRIPT_DIR}/delete-resource.sh "${NAME_PATTERN}"
${SCRIPT_DIR}/delete-vpc.sh "${NAME_PATTERN}" --all-regions
${SCRIPT_DIR}/delete-access-group.sh "${NAME_PATTERN}"
${SCRIPT_DIR}/delete-resource-group.sh "${NAME_PATTERN}" --purge-volumes
