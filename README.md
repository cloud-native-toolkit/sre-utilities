# sre-utilities

Utilities and helper scripts for SREs

## Scripts

### Git scripts

Scripts for interacting with git repositories.

#### clone-org.sh

This script clones all of the repositories in a GitHub organization to the local filesystem

## IBM Cloud scripts

Scripts for interacting with an IBM Cloud account

#### delete-vpc.sh

Performs a cascading delete of a VPC.

#### delete-unbound-volumes.sh

Deletes any volumes in the account that are currently not attached to a cluster.

#### delete-all-resources-for-user.sh

Deletes all resources created by a particular user.

## Cloud init

Collection of cloud init scripts. These scripts can be used to provision a cloud server instance (like a VSI on IBM Cloud) or a local VM using a tool like [multipass](https://multipass.run/).

To use a cloud init script with multipass, run the following commands:

```shell
multipass launch --name {name} --cloud-init ./cloud-init/cli-tools.yaml
```

where:
- `{name}` is any name you want to give to the vm (e.g. `cli-tools`)

You can then access the VM by running:

```shell
multipass shell {name}
```

### cli-tools.yaml

The cli-tools cloud init script prepares a VM with the same tools available in the `quay.io/cloudnativetoolkit/cli-tools-ibmcloud` container image. Particularly:

- terraform
- terragrunt
- git
- jq
- yq
- oc
- kubectl
- helm
- ibmcloud cli

