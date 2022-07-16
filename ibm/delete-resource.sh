#!/bin/bash

NAME="$1

ibmcloud resource service-keys --instance-name $NAME --output JSON | jq -r '.[] | .id' | while read key; do 
  ibmcloud resource service-key-delete -f $key; 
done

ibmcloud resource service-instance-delete -f $NAME

