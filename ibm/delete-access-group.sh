SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

source ${SCRIPT_DIR}/_common_functions.sh

usage() {
  echo "Deletes all access groups that meet the provided regex pattern"
  echo ""
  echo "usage: delete-access-group.sh {NAME_PATTERN}"
  echo ""
  echo "where:"
  echo "  - NAME_PATTERN - is the regex pattern for the access group names"
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

ibmcloud iam access-groups --output json | \
  jq --arg NAME "${NAME_PATTERN}" -r '.[] | select(.name | test($NAME; "i")) | .name' | \
  while read name; 
do
  echo "Deleting access group: ${name}"
  ibmcloud iam access-group-delete -f -r -a "${name}"
done
