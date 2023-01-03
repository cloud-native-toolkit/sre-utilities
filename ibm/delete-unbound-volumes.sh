set -e
if ! command -v jq 1> /dev/null 2> /dev/null; then
  echo "jq cli not found" >&2
  exit 1
fi

if ! command -v ibmcloud 1> /dev/null 2> /dev/null; then
  echo "ibmcloud cli not found" >&2
  exit 1
fi

ibmcloud target
echo
echo "Deleting all unbound volumes for the currently logged in user/region..."
read -p "Are you sure? (Y/N)  " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
fi

VOLUMES=$( ibmcloud is volumes --output JSON )
set +e
for volume in $(echo "$VOLUMES" | jq -r '.[] | @base64'); do
    _jq() {
     echo ${volume} | base64 --decode | jq -r ${1}
    }
   VOLUME=$(_jq)
   NAME=$(echo $VOLUME | jq '.name' -r)
   ID=$(echo $VOLUME | jq '.id' -r)
   STATUS=$(echo $VOLUME | jq '.status' -r)
   ATTACHMENTS=$(echo $VOLUME | jq '.volume_attachments | length')

   if [ "$ATTACHMENTS" -eq "0" ]; then
     #echo "$NAME: $STATUS"
     if [ "$STATUS" == "available" ] || [ "$STATUS" == "failed" ]; then

        echo "Deleting volume $NAME with $ATTACHMENTS attachments...";

        ibmcloud is volume-delete "$ID" -f
      fi
   fi
done