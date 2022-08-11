#!/bin/bash
SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

source ${SCRIPT_DIR}/_common_functions.sh

NAME_PATTERN="$1"

if [[ -z "${NAME_PATTERN}" ]]; then
  echo "The name or regex pattern of the cluster(s) should be provided as the first argument" >&2
  return 1
fi

check_prereqs || exit 1

CLUSTERS=$(ibmcloud ks cluster ls | grep -E "${NAME_PATTERN}" | sed -E 's/^([^ ]+).*/\1/g')

echo "${CLUSTERS}" | while read cluster_name; do
  delete_cluster "${cluster_name}"
done

echo "${CLUSTERS}" | while read cluster_name; do
  wait_for_cluster_to_be_deleted "${cluster_name}"
done
