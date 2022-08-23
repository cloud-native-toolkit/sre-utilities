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
echo "List the Consumption Usage for range "
echo "================================="
#az costmanagement export show --name "EcosystemExport" --scope "subscriptions/c35b3277-7ef2-4013-b5d3-8e3cfca81c12"

startdate=$1
enddate=$2
billing=$3

az consumption usage list --billing-period-name $billing --start-date $1 --end-date $2 -o table

#az billing subscription show --account-name 887ef35a-df6f-4a95-b179-ee1b5965e7d7 
#--profile-name "IBM Ecosystem Partner Engineering"
echo "================================="







