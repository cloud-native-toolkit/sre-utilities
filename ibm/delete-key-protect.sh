#!/bin/bash

#############
# word of caution: for some reason, some key protect instances will give a permission error when you try to delete keys, even when you do have permission.
# for example: kp.Error: correlation_id='7409aec8-e1ca-4d45-8d1b-78e34cb5aa0b', msg='Unauthorized: The user does not have access to the specified resource'
# the workaroudn for these cases is to just go to the UI and delete manually.  It doesn't happen to every instance.
#############

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

source ${SCRIPT_DIR}/_common_functions.sh

NAME_PATTERN="$1"

if [[ -z "${NAME_PATTERN}" ]]; then
  echo "The name or regex pattern of the VPC(s) should be provided as the first argument" >&2
  return 1
fi

check_prereqs || exit 1


INSTANCES=$( ibmcloud resource service-instances --output json )


set +e
for instance in $(echo "$INSTANCES" | jq -r '.[] | @base64'); do
  _jq() {
    echo ${instance} | base64 --decode | jq -r ${1}
  }
  INSTANCE=$(_jq)
  NAME=$(echo $INSTANCE | jq '.name' -r)
  CRN=$(echo $INSTANCE | jq '.crn' -r)


  if  [[ $NAME == "$NAME_PATTERN"* ]] && [[ $CRN == "crn:v1:bluemix:public:kms"* ]];
  then
    
    echo "Deleting Key Protect keys for $NAME"
    GUID=$(echo $INSTANCE | jq '.guid' -r)
    
    KEYS=$( ibmcloud kp keys -i $GUID --output json )

    for key in $(echo "$KEYS" | jq -r '.[] | @base64'); do
      __jq() {
      echo ${key} | base64 --decode | jq -r ${1}
      }
      KEY=$(__jq)
      KEY_NAME=$(echo $KEY | jq '.name' -r)
      KEY_ID=$(echo $KEY | jq '.id' -r)

      echo "deleting $KEY_NAME with id $KEY_ID"
      ibmcloud kp key delete $KEY_ID -i $GUID -f
    done
    delete_resource "${NAME}"

    echo " "
  fi

done