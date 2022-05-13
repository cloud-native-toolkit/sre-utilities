#!/bin/bash

USERNAME="$1"

if [[ -z "${USERNAME}" ]]; then
  echo "usage: delete-resources.sh USERNAME" >&2
  echo "  where: USERNAME is the email address of the user" >&2
  exit 1
fi

if ! command -v jq 1> /dev/null 2> /dev/null; then
  echo "jq cli not found" >&2
  exit 1
fi

if ! command -v ibmcloud 1> /dev/null 2> /dev/null; then
  echo "ibmcloud cli not found" >&2
  exit 1
fi

USERID=$(ibmcloud account users --output json | jq --arg USERNAME "${USERNAME}" -r '.[] | select(.userId == $USERNAME) | .ibmUniqueId')

if [[ -z "${USERID}" ]]; then
  echo "Unable to find user: ${USERNAME}" >&2
  exit 1
else
  echo "Found userid for username(${USERNAME}): ${USERID}"
fi

ibmcloud resource service-instances --output json | jq --arg USERID "${USERID}" -r '.[] | select(.created_by==$USERID) | .id' | \
while read id; do
  ibmcloud resource service-keys --instance-id "${id}" --output json | jq -r '.[] | .id' | \
  while read key_id; do
    ibmcloud resource service-key-delete "${key_id}" --force
  done

  ibmcloud resource service-instance-delete "${id}" --force
done