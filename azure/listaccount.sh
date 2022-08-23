#!/bin/bash


# In order to use this script you must have installed the Azure
# Cloud CLI. 
# Visit and follow instructions for local OS - https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest | sh



#Login to Azure 
#TODO - replace with Service Principal

#Azure login
#az login -u "${1}" -p "${2}"
#A web browser has been opened at https://login.microsoftonline.com/organizations/oauth2/v2.0/authorize. Please continue the login in the web browser. If no web browser is available or if the web browser fails to open, use device code flow with `az login --use-device-code`
az login 

# get the current default subscription using show
echo "================================="
echo "Show Active Tenant Details "
echo "================================="
az account tenant list

# store the default subscription  in a variable
subscriptionId="$(az account list --query "[?isDefault].id" -o tsv)"

echo "================================="
echo Account Subscription ID : $subscriptionId
echo "================================="
#echo $subscriptionId

# get the current default subscription using show
#echo "================================="
#echo "Show Account Details -- "
#echo "================================="
az account show --output table






