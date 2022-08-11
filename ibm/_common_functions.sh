check_prereqs() {
  if ! command -v jq 1> /dev/null 2> /dev/null; then
    echo "jq cli not found" >&2
    exit 1
  fi

  if ! ibmcloud resource service-instances 1> /dev/null; then
    exit 1
  fi
}

delete_volume() {
    local id="$1"

    ibmcloud is volume-delete -f "${id}" || exit 0

    while ibmcloud is volume "${id}" 1> /dev/null 2> /dev/null; do
      echo "  Waiting for volume to be deleted: ${id}"
      sleep 10
    done
    
    echo "Volume deleted: ${id}"
}

delete_cluster() {
    local cluster="$1"

    ibmcloud ks cluster rm -c "${cluster}" --force-delete-storage -f || exit 0
}

wait_for_cluster_to_be_deleted() {
    local cluster="$1"

    while ibmcloud ks cluster get -c "${cluster}" 1> /dev/null 2> /dev/null; do
      echo "  Waiting for cluster to be deleted: ${cluster}"
      sleep 30
    done
    
    echo "Cluster deleted: ${cluster}"
}

delete_resource() {
  local NAME="$1"

  echo ""
  echo "=== Deleting resource: ${NAME}"
  echo ""
  
  ibmcloud resource service-keys --instance-name $NAME --output JSON | jq -r '.[] | .id' | while read key; do 
    ibmcloud resource service-key-delete -f $key; 
  done

  ibmcloud resource service-instance-delete -f $NAME
}

delete_vpc() {
  local VPC_NAME="$1"

  echo ""
  echo "=== Deleting vpc and related resources: ${VPC_NAME} ==="
  echo ""

  set -e

  echo "*** Deleting virtual server instances..."
  echo ""

  ibmcloud is instances --all-resource-groups --output JSON | \
    jq -c --arg VPC_NAME $VPC_NAME '.[] | select(.vpc.name == $VPC_NAME)' | \
    while read instance; 
  do

    id=$(echo "$instance" | jq -r '.id')
    name=$(echo "$instance" | jq -r '.name')

    echo $instance | jq -c '.network_interfaces | .[] | .floating_ips | .[]' | \
      while read floating_ip; 
    do

      floating_ip_id=$(echo "$floating_ip" | jq -r '.id')
      floating_ip_name=$(echo "$floating_ip" | jq -r '.name')
      
      echo "Releasing instance floating ip: ${floating_ip_name} (${floating_ip_id})"
      ibmcloud is floating-ip-release -f "${floating_ip_id}"
    done 

    echo "Stopping instance: ${name} (${id})"
    ibmcloud is instance-stop -f "${id}"

    count=0
    while [[ $(ibmcloud is instance "${id}" --output JSON | jq -r '.status') == "stopping" ]] && [[ ${count} -lt 10 ]]; do
      echo "Waiting for instance to stop: ${name} (${id})"
      sleep 30

      count=$((count + 1))
    done
    if [[ $count -eq 10 ]]; then
      echo "Timed out waiting for instance to stop: ${name} (${id})"
      exit 1
    fi

    echo "Deleting instance: ${name} (${id})"
    ibmcloud is instance-delete -f "${id}"

    count=0
    while ibmcloud is instance "${id}" && [[ ${count} -lt 10 ]]; do
      echo "Waiting for instance to be deleted: ${name} (${id})"
      sleep 30

      count=$((count + 1))
    done
    if [[ $count -eq 10 ]]; then
      echo "Timed out waiting for instance to be deleted: ${name} (${id})"
      exit 1
    fi
  done

  echo ""
  echo "*** Deleting endpoint gateways..."
  echo ""

  ibmcloud is endpoint-gateways --all-resource-groups --output JSON | \
    jq -c --arg VPC_NAME sms-vpn-mgmt-vpc '.[] | select(.vpc.name == $VPC_NAME)' | \
    while read endpoint;
  do
    
    id=$(echo "$endpoint" | jq -r '.id')
    name=$(echo "$endpoint" | jq -r '.name')

    echo "$endpoint" | jq -c '.ips | .[]' | \
      while read endpoint_ip;
    do
      ip_id=$(echo "$endpoint_ip" | jq -r '.id')
      ip_name=$(echo "$endpoint_ip" | jq -r '.name')
      
      echo "Unbinding endpoint gateway ip: ${ip_name} (${ip_id})"
      ibmcloud is endpoint-gateway-reserved-ip-unbind -f "${id}" --reserved-ip-id "${ip_id}"
    done

    echo "Deleting endpoint gateway: ${name} (${id})"
    ibmcloud is endpoint-gateway-delete -f "${id}"
  done

  echo ""
  echo "*** Deleting subnets..."
  echo ""

  ibmcloud is subnets --all-resource-groups --output JSON | \
    jq -c --arg VPC_NAME "${VPC_NAME}" '.[] | select(.vpc.name == $VPC_NAME)' | \
    while read subnet;
  do

    id=$(echo "$subnet" | jq -r '.id')
    name=$(echo "$subnet" | jq -r '.name')
    public_gateway_id=$(echo "$subnet" | jq -r '.public_gateway.id // ""')
    public_gateway_name=$(echo "$subnet" | jq -r '.public_gateway.name // ""')

    if [[ -n "${public_gateway_id}" ]]; then
      echo "Detach public gateway from subnet: ${public_gateway_name} (${public_gateway_id})"
      ibmcloud is subnet-public-gateway-detach "${id}" --force
    fi

    ibmcloud is subnet-reserved-ips "${id}" --output json | \
      jq -c '.[]' | \
      while read reserved_ip;
    do
      ip_id=$(echo "$reserved_ip" | jq -r '.id')
      ip_name=$(echo "$reserved_ip" | jq -r '.name')
      ip_owner=$(echo "$reserved_ip" | jq -r '.owner')

      if [[ "${ip_owner}" != "provider" ]]; then
        echo "Deleting reserved ip: ${ip_name} (${ip_id})"
        ibmcloud is subnet-reserved-ip-delete -f "${id}" "${ip_id}" || echo "Error deleting reserved ip"
      else
        echo "Skipping reserved ip owned by provider: ${ip_name} (${ip_id})"
      fi
    done
    
    echo "Deleting subnet: ${name} (${id})"
    ibmcloud is subnet-delete -f "${id}"
  done

  echo ""
  echo "*** Deleting public gateways..."
  echo ""

  ibmcloud is public-gateways --all-resource-groups --output JSON | \
    jq -c --arg VPC_NAME "${VPC_NAME}" '.[] | select(.vpc.name == $VPC_NAME)' | \
    while read gateway;
  do

    id=$(echo "$gateway" | jq -r '.id')
    name=$(echo "$gateway" | jq -r '.name')
    floating_ip_id=$(echo "$gateway" | jq -r '.floating_ip.id')
    floating_ip_name=$(echo "$gateway" | jq -r '.floating_ip.name')

    echo "Deleting public gateway: ${name} (${id})"
    ibmcloud is public-gateway-delete -f "${id}"
    
  #  if [[ -n "${floating_ip_id}" ]]; then
  #    echo "Releasing gateway floating ip: ${floating_ip_name} (${floating_ip_id})"
  #    ibmcloud is floating-ip-release -f "${floating_ip_id}"
  #  fi
  done

  sleep 10

  echo ""
  echo "*** Deleting VPC..."
  echo ""

  ibmcloud is vpcs --all-resource-groups --output JSON | \
    jq -c --arg VPC_NAME "${VPC_NAME}" '.[] | select(.name == $VPC_NAME)' | \
    while read vpc; 
  do

    id=$(echo "$vpc" | jq -r '.id')
    name="${VPC_NAME}"

    echo "Deleting VPC: ${name} (${id})"
    ibmcloud is vpc-delete -f "${id}"
  done
}
