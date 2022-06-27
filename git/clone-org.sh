ORG=$1

if [ -z "$ORG" ]
then
  echo "No github org defined.  Usage: \"./clone-org.sh myorg\""
  exit 1
fi

echo "Cloning entire $ORG org..."


gh repo list $ORG --limit 1000 | while read -r repo _; do
  gh repo clone "$repo" "$repo"
done

