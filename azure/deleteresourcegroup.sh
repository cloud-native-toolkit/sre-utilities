#!/bin/bash

# This script is **destructive** and will delete a lot of Azure
# Cloud resources. Use with caution!

# In order to use this script you must have installed the Azure
# Cloud CLI. 
# Visit and follow instructions for local OS - https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest | sh


# Lastly, you must be authenticated and have targetted
# a resource group. To do so, run the following:

# az login -u <username> -p <password>
# az group show --name exampleGroup


# usage() { echo "Usage: $0 [-n] [-c <config-file>]" 1>&2; exit 1; }

# NO_DRY_RUN=''
# CONFIG_FILE=''
# while getopts "nc:" o; do
#     case "${o}" in
#         n)
#             n=${OPTARG}
#             NO_DRY_RUN=1
#             ;;
#         c)
#             c=${OPTARG}
#             CONFIG_FILE=$c
#             ;;
#         *)
#             usage
#             ;;
#     esac
# done

# if [ "$CONFIG_FILE" ]; then
#     echo "Attempting to use config file at location: $CONFIG_FILE"
#     # Ensure config file exists
#     if ! test -f ${CONFIG_FILE};
#     then
#         echo "specified config file ${CONFIG_FILE} not found"
#         exit 1
#     fi
# else
#     CONFIG_FILE='.azurecloud-nuke'
#     echo "Attempting to use config file at default location: $CONFIG_FILE"
# fi

# if [ "${NO_DRY_RUN}" ]; then
#     echo "The (-n) flag was found. Will begin to delete all resources."
#     NO_DRY_RUN=1
# else
#     echo "No (-n) flag found. Will NOT delete any resources."
#     NO_DRY_RUN=0
# fi

# echo "================================="
# echo "NO_DRY_RUN = ${NO_DRY_RUN}"
# echo "CONFIG_FILE = ${CONFIG_FILE}"
# echo "================================="

# # Usage: get_or_create_user <name_or_id>
# function check_config_file() {
#     if test -f ${CONFIG_FILE} && grep -Fxq "${1}" ${CONFIG_FILE}
#     then
#         echo "skipping ${name} as it exists in ${CONFIG_FILE}"
#         continue
#     fi
# }

#Login to Azure 
#TODO - replace with Service Principal

#Azure login
#az login -u "${1}" -p "${2}"
#A web browser has been opened at https://login.microsoftonline.com/organizations/oauth2/v2.0/authorize. Please continue the login in the web browser. If no web browser is available or if the web browser fails to open, use device code flow with `az login --use-device-code`
az login

resourceGroup=$1

# Resource Group List
echo "================================="
echo "Resource group List Before Delete "
echo "================================="
az group list --output table
echo "================================="

# Resource Group
echo "Resource group: Processing to delete "

if [ $(az group exists --name $resourceGroup) = true ]; then 
   echo - The $resourceGroup resource group exist
   az group delete --name $resourceGroup -y # --no-wait
else
   echo - The $resourceGroup resource group does not exist
fi

echo - The $resourceGroup resource group deleted from the account.

# Resource Group List
echo "================================="
echo "Resource group List After Delete "
echo "================================="
az group list --output table


