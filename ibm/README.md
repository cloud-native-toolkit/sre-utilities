# IBM Cloud SRE utilities

This directory provides a collection of utilities to help manage (particularly *delete*) resources within an IBM Cloud account.

## Prerequisites

These commands all assume that the `ibmcloud` and `jq` clis have been installed, that the `infrastructure-service` plugin to the `ibmcloud` cli has been installed and that the `ibmcloud` cli has already been used to log into the target IBM Cloud account.

### ibmcloud cli

The instructions to install the `ibmcloud` cli can be found here - https://cloud.ibm.com/docs/cli?topic=cli-install-ibmcloud-cli

### ibmcloud infrastructure-service plugin

Once the `ibmcloud` cli has been installed, the infrastructure-service plugin can be installed with the following command:

```shell
ibmcloud plugin install infrastructure-service
```

**Note:** Even if the plugin has been installed previously, it is a good idea to make sure it has been upgraded to the latest version.

### jq cli

The `jq` cli provides a command-line utility to work with and manipulate json objects. The instructions to install the `jq` cli can be found here - https://stedolan.github.io/jq/download/

### IBM Cloud login

The instructions and examples for logging into IBM Cloud with the `ibmcloud` cli can be found here - https://cloud.ibm.com/docs/cli?topic=cli-ibmcloud_cli#ibmcloud_login

## Utilities

### delete-cluster.sh

This command will issue the command delete a cluster (and associated volumes) and wait for the cluster to be deleted. The input to the command is a cluster name or regex pattern that matches a set of clusters that should be deleted.  The names of clusters in the account can be listed with `ibmcloud ks cluster ls`.

#### Examples

To delete a single cluster, provide the cluster name as the first argument. In this example, the cluster name is `my-cluster`:

```shell
./delete-cluster.sh my-cluster
```

To delete multiple clusters, provide a partial name or regular expression that matches the target cluster names. In this example, the regular expression `^qo|^qp` is provided which matches all clusters whose name starts with "qo" or starts with "qp":

```shell
./delete-cluster.sh "^qo|^qp"
```

### delete-resource.sh

Delete the service resource(s) that match the given name or regular expression. The names of resources in the account can be listed with `ibmcloud resource service-instances` or `ibmcloud resource service-instances --output json | jq -r '.[] | .name'`

#### Examples

To delete a single resource, provide the resource name as the first argument. In this example, the resource name is `my-database`:

```shell
./delete-resource.sh my-database
```

To delete multiple resources, provide a partial name or regular expression that matches the target resource names. In this example, the regular expression `^qo|^qp` is provided which matches all resources whose name starts with "qo" or starts with "qp":

```shell
./delete-resource.sh "^qo|^qp"
```

### delete-vpc.sh

Delete the vpc (and all contained resources) that match the given name or regular expression. VPCs apis are scoped to a region. By default the command will delete the matching VPCs in the currently targeted region. If you want to match VPCs across all regions, add `--all-regions` as the second argument to the script. 

To list the vpcs in the current region, run:

```shell
ibmcloud is vpcs --output json | jq -r '.[] | .name'
``` 

To list all of the vpcs across all regions, run:

```shell
current_region=$(ibmcloud target --output json | jq -r '.region.name')

ibmcloud regions --output json | \
  jq -r '.[] | .Name' | \
  while read region; 
do
  ibmcloud target -r "${region}" 1> /dev/null 2> /dev/null || continue
  ibmcloud is vpcs --output json 2> /dev/null | jq -r '.[] | .name'
done

ibmcloud target -r "${current_region}" 1> /dev/null 2> /dev/null
```

#### Examples

To delete a single vpc (and its related resources), provide the vpc name as the first argument. In this example, the vpc name is `my-vpc`:

```shell
./delete-vpc.sh my-vpc
```

To delete multiple vpcs, provide a partial name or regular expression that matches the target vpc names. In this example, the regular expression `^qo|^qp` is provided which matches all vpcs whose name starts with "qo" or starts with "qp":

```shell
./delete-vpc.sh "^qo|^qp"
```

To delete multiple vpcs across all regions, provide a partial name or regular expression that matches the target vpc names and the `--all-regions` flag as the second argument. In this example, the regular expression `^qo|^qp` is provided which matches all vpcs whose name starts with "qo" or starts with "qp":

```shell
./delete-vpc.sh "^qo|^qp" --all-regions
```

### delete-access-group.sh

Delete the access group(s) that match the name or regular expression provided. The script does a case-insensitive match of the name so "test" and "TEST" will both match "TEST". The list of access groups can be displayed with `ibmcloud iam access-groups`

#### Examples

To delete a single access group, provide the access group name as the first argument. In this example, the vpc name is `MY_ACCESS_GROUP`:

```shell
./delete-access_group.sh MY_ACCESS_GROUP
```

To delete multiple access groups, provide a partial name or regular expression that matches the target access group names. In this example, the regular expression `^qo|^qp` is provided which matches all access groups whose name starts with "qo" or "QO" or starts with "qp" or "QP":

```shell
./delete-access-group.sh "^qo|^qp"
```

### delete-resource-group.sh

Deletes resource group(s) for a given name or regular expression. The resource group must already be (mostly) empty before a resource group can be deleted successfully. The one exception is volumes and this script will optionally purge the volumes if `--purge-volumes` is provided as the second argument. The list of resource groups can be displayed by running `ibmcloud resource groups`

#### Examples

To delete a single resource group, provide the resource name as the first argument. In this example, the resource group name is `my-resource-group`:

```shell
./delete-resource-group.sh my-resource-group
```

To delete multiple resource groups, provide a partial name or regular expression that matches the target resource group names. In this example, the regular expression `^qo|^qp` is provided which matches all resource groups whose name starts with "qo" or starts with "qp":

```shell
./delete-resource-group.sh "^qo|^qp"
```

To delete a resource group and any volumes associated with the resource group, pass `--purge-volumes` as the second argument.

```shell
./delete-resource-group.sh my-resource-group --purge-volumes
```

### delete-all.sh

Deletes all of the resources that match a name or name pattern. This script makes use of the other scripts and calls them in order:

- delete-cluster.sh
- delete-resource.sh
- delete-vpc.sh (all regions)
- delete-access-group.sh
- delete-resource-group.sh (purge volumes)

#### Examples

To delete a collection of resources, provide a partial name or regular expression that matches the target resources. In this example, the regular expression `^qo|^qp` is provided which matches all resources whose name starts with "qo" or "QO" or starts with "qp" or "QP":

```shell
./delete-all.sh "^qo|^qp"
```

### delete-all-resources-for-user.sh

Deletes all of the resource instances (not including clusters and vpcs) that were created by a particular user by email address. 

#### Examples

To delete the resources created by `someone@somewhere.com` run:

```shell
./delete-all-resources-for-user.sh someone@somewhere.com
```

### delete-unbound-volumes.sh

Deletes all volumes across all resource groups in the current region that aren't bound to another resource (e.g. a cluster).

#### Examples

There are no arguments for the command but it will confirm to proceed before executing.

```shell
./delete-unbound-volumes.sh
```

### purge-volumes.sh

Deletes all the volumes found in the provided resource group(s) or regular expression pattern. By default the command runs against the currently targeted region but can delete volumes across all regions by passing `--all-regions` as the second argument.

#### Examples

To purge the volumes for a resource group named `my-rg` in the current region, run:

```shell
./purge-volumes.sh my-rg
```

To purge the volumes in the current region for resource groups that match the pattern `^my-`, run:

```shell
./purge-volumes.sh "^my-"
```

To purge the volumes across all regions for resource groups that match the pattern `^my-`, run:

```shell
./purge-volumes.sh "^my-" --all-regions
```
