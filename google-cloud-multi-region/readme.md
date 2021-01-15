# Multi Region / Multi Cluster (work in progress)

# Prerequisites

* `terraform`
* `gcloud`
* `kpt`
* `istioctl`

# Installation


## Steps
1. Prep a repo for ACM, including ssh key based access, similar to the `/google-cloud` blueprint
1. clone this repo
1. cd `google-cloud-multi-region/infrastructure`
1. customize shared.tf.example
    1. Set backend "gcs" to a GCS bucket that your user has access to
    1. Make sure billing account ID is set correctly
    1. Update PROJECT_PREFIX
    1. Set `project_root_path`
    1. Set `config_sync_ssh_auth_key_path` to a filesystem path that contains the key needed for ACM repo access.
1. terraform init / plan / apply
1. After resource creation via terraform is complete: cd up one dir to `/google-cloud-multi-region`
1. Update this line in `main.sh`:
```
export WORKSTATION_SRC_ROOT=<PATH TO THE DIRECTORY ABOVE THIS REPOSITORY>
```
Note that these lines need updating too (to be fixed before merging):
```
pushd "${WORKSTATION_SRC_ROOT}/pci-anthos/google-cloud-multi-region/infrastructure" &> /dev/null 
...
export APP_DIR="${WORKSTATION_SRC_ROOT}/pci-anthos/google-cloud-multi-region/app/store"
export KUBECONFIG="${WORKSTATION_SRC_ROOT}/pci-anthos/google-cloud-multi-region/private/${APP_PROJECT_ID}-kubeconfig"
...
# istioctl is expected at:
export ISTIOCTL_CMD="${WORKSTATION_SRC_ROOT}/istio-"${ASM_VERSION}"/bin/istioctl"
```

```sh
source scripts/main.sh
run_all
```

