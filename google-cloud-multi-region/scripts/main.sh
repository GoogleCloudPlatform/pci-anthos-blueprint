#!/usr/bin/env bash -ex

function run_all {
  set_environment_variables
  set_up_credentials
  install_asm
  install_microservices_demo
  deploy_microservices_via_mcs
  verify_app_via_mcs
}

function deploy_microservices_via_mcs {
  enable_multicluster_ingress
  create_mci_and_mcs
  describe_crds
}

function verify_app_via_mcs {
  VIP=$(kubectl --context ${CLUSTER_r3_1} -n istio-system get multiclusteringress -o jsonpath="{.items[].status.VIP}")
  echo "The Multicluster Ingress VIP: $VIP"
  echo "Does a curl to the VIP via http return a 200?"
  curl -Is http://$VIP |grep 200
  echo "Does a curl -k to the VIP via https return a 200?"
  curl -Isk https://$VIP |grep 200
}

# if we keep this model, the exports here can parse terraform output. 
function set_environment_variables {
  export WORKSTATION_SRC_ROOT=<PATH TO THE DIRECTORY ABOVE THIS REPOSITORY>
  #TODO: The variables used here need more abstraction
  pushd "${WORKSTATION_SRC_ROOT}/pci-anthos/google-cloud-multi-region/infrastructure" &> /dev/null 

  export PROJECT_ID=$(terraform output -json|jq -r .app_project_raw_id.value)
  echo "PROJECT_ID: $PROJECT_ID"
  echo "TODO: the variable PROJECT_ID needs to be removed, there are multiple projects that it can be referring to"

  export APP_PROJECT_ID="${PROJECT_ID}"
  echo "APP_PROJECT_ID: $APP_PROJECT_ID"

  export PROJECT_NUM=$(gcloud projects describe ${APP_PROJECT_ID} --format='value(projectNumber)')
  echo "PROJECT_NUM: $PROJECT_NUM"

  export CLUSTER_r1_1=$(terraform output -json|jq -r .r1_1.value)
  echo "CLUSTER_r1_1: ${CLUSTER_r1_1}"

  export CLUSTER_r1_1_location=$(terraform output -json|jq -r .r1_1_location.value)
  echo "CLUSTER_r1_1_location: ${CLUSTER_r1_1_location}"

  export CLUSTER_r1_2=$(terraform output -json|jq -r .r1_2.value)
  echo "CLUSTER_r1_2: ${CLUSTER_r1_2}"

  export CLUSTER_r1_2_location=$(terraform output -json|jq -r .r1_2_location.value)
  echo "CLUSTER_r1_2_location: ${CLUSTER_r1_2_location}"

  export CLUSTER_r2_1=$(terraform output -json|jq -r .r2_1.value)
  echo "CLUSTER_r2_1: ${CLUSTER_r2_1}"

  export CLUSTER_r2_1_location=$(terraform output -json|jq -r .r2_1_location.value)
  echo "CLUSTER_r2_1_location: ${CLUSTER_r2_1_location}"

  export CLUSTER_r2_2=$(terraform output -json|jq -r .r2_2.value)
  echo "CLUSTER_r2_2: ${CLUSTER_r2_2}"

  export CLUSTER_r2_2_location=$(terraform output -json|jq -r .r2_2_location.value)
  echo "CLUSTER_r2_2_location: ${CLUSTER_r2_2_location}"

  export CLUSTER_r3_1=$(terraform output -json|jq -r .r3_1.value)
  echo "CLUSTER_r3_1: ${CLUSTER_r3_1}"

  export CLUSTER_r3_1_location=$(terraform output -json|jq -r .r3_1_location.value)
  echo "CLUSTER_r3_1_location: ${CLUSTER_r3_1_location}"

  export APP_DIR="${WORKSTATION_SRC_ROOT}/pci-anthos/google-cloud-multi-region/app/store"
  export KUBECONFIG="${WORKSTATION_SRC_ROOT}/pci-anthos/google-cloud-multi-region/private/${APP_PROJECT_ID}-kubeconfig"
  export ASM_VERSION=1.6.11-asm.1
  export ASM_LABEL=asm-1611-1
  export ISTIOCTL_CMD="${WORKSTATION_SRC_ROOT}/istio-"${ASM_VERSION}"/bin/istioctl"

  popd &> /dev/null 
}

function set_up_credentials {
  declare -A clusters
  clusters=( ["r1-1"]="us-west1-a" ["r1-2"]="us-west1-a" ["r2-1"]="us-west2-a" ["r2-2"]="us-west2-a" ["r3-1"]="us-central1-a")
  for this_cluster in ${!clusters[@]} ; do
    gcloud --project "${APP_PROJECT_ID}" container clusters get-credentials "${this_cluster}" --zone "${clusters[$this_cluster]}" &> /dev/null 
    kubectl config delete-context "${this_cluster}" &> /dev/null || true
    kubectl config rename-context "gke_${APP_PROJECT_ID}_${clusters[$this_cluster]}_${this_cluster}" "${this_cluster}" &> /dev/null 
  done
  kubectl config get-contexts
}

# Installs Anthos Service Mesh
function install_asm {
  declare -A clusters
  # ASM should not installed on r3_1, so it is not included here
  clusters=( ["r1-1"]="us-west1-a" ["r1-2"]="us-west1-a" ["r2-1"]="us-west2-a" ["r2-2"]="us-west2-a" )

  for this_cluster in ${!clusters[@]} ; do
    _install_asm_via_kpt "$this_cluster" "${clusters[$this_cluster]}"
  done

  # from each cluster to each other one, run cross_cluster_service_secret
  for client_cluster in ${!clusters[@]} ; do
    for target_cluster in ${!clusters[@]} ; do
      # a cluster does not need cross_cluster_service_secret to be run on itself
      if [ "$client_cluster" != "$target_cluster" ] ; then
          cross_cluster_service_secret $client_cluster $target_cluster
      fi
    done
  done
}

# helper function for install_asm
# Usage:
# _install_asm_via_kpt CLUSTER CLUSTER_ZONE
# Example:
# _install_asm_via_kpt in-scope us-west2-a
function _install_asm_via_kpt {
  THIS_CLUSTER=$1
  THIS_CLUSTER_ZONE=$2
  # echo "THIS_CLUSTER: $THIS_CLUSTER"
  # echo "THIS_CLUSTER_ZONE: $THIS_CLUSTER_ZONE"
  # echo "APP_PROJECT_ID: $APP_PROJECT_ID"
  # echo "PROJECT_NUM: $PROJECT_NUM"
  # TODO: This needs investigation. kpt uses vars from the gcloud config, but they are explicitly set afterwards #267
  gcloud config set project ${APP_PROJECT_ID}
  echo "installing ASM via kpt on ${THIS_CLUSTER} in zone: ${THIS_CLUSTER_ZONE}"

  TMPDIR=$(mktemp -d -t kpt-XXXXX)
  # echo "TMPDIR: $TMPDIR"
  pushd $TMPDIR &> /dev/null

  kpt pkg get https://github.com/GoogleCloudPlatform/anthos-service-mesh-packages.git/asm@release-1.6-asm ${THIS_CLUSTER}
  kpt cfg set ${THIS_CLUSTER} gcloud.container.cluster ${THIS_CLUSTER}
  kpt cfg set ${THIS_CLUSTER} gcloud.core.project ${APP_PROJECT_ID}
  kpt cfg set ${THIS_CLUSTER} gcloud.compute.location ${THIS_CLUSTER_ZONE}
  kpt cfg set ${THIS_CLUSTER} gcloud.project.environProjectNumber ${PROJECT_NUM}
  kpt cfg set ${THIS_CLUSTER} anthos.servicemesh.profile asm-gcp
  kpt cfg list-setters ${THIS_CLUSTER}/

  ${ISTIOCTL_CMD} \
    --context ${THIS_CLUSTER} \
    install \
    -f ${THIS_CLUSTER}/cluster/istio-operator.yaml \
    --set revision=asm-1611-1 \
    -f ${WORKSTATION_SRC_ROOT}/pci-anthos/google-cloud-multi-region/asm/internal-load-balancer.yml

  kubectl --context ${THIS_CLUSTER} apply -f ${THIS_CLUSTER}/canonical-service/controller.yaml

  popd &> /dev/null
  echo "Completed installing ASM via kpt on ${THIS_CLUSTER} in zone: ${THIS_CLUSTER_ZONE} \n"
}

# Configure cross-cluster service registry. The following command creates a secret in each cluster with the other cluster's
# configuration so it can access the other cluster's API.
# The CLIENT_CLUSTER will have the secret created so it can reach TARGET_CLUSTER
# Usage:
# cross_cluster_service_secret CLIENT_CLUSTER TARGET_CLUSTER
function cross_cluster_service_secret {
  CLIENT_CLUSTER=$1
  TARGET_CLUSTER=$2
  ${ISTIOCTL_CMD} x create-remote-secret \
    --context=${TARGET_CLUSTER} \
    --name ${TARGET_CLUSTER} | kubectl --context=${CLIENT_CLUSTER} apply -f -
}

# Installs the microservices-demo
function install_microservices_demo {
  # Application resources per namespace on both in-scope clusters (CLUSTER_r1_1, and CLUSTER_r2_1)
  kubectl --context ${CLUSTER_r1_1} -n paymentservice     apply -f ${APP_DIR}/cluster/in-scope/namespaces/paymentservice
  kubectl --context ${CLUSTER_r2_1} -n paymentservice     apply -f ${APP_DIR}/cluster/in-scope/namespaces/paymentservice

  kubectl --context ${CLUSTER_r1_1} -n checkoutservice    apply -f ${APP_DIR}/cluster/in-scope/namespaces/checkoutservice
  kubectl --context ${CLUSTER_r2_1} -n checkoutservice    apply -f ${APP_DIR}/cluster/in-scope/namespaces/checkoutservice

  kubectl --context ${CLUSTER_r1_1} -n frontend           apply -f ${APP_DIR}/cluster/in-scope/namespaces/frontend
  kubectl --context ${CLUSTER_r2_1} -n frontend           apply -f ${APP_DIR}/cluster/in-scope/namespaces/frontend

  # store-out-of-scope resources required on both in-scope clusters
  kubectl --context ${CLUSTER_r1_1} -n store-out-of-scope apply -f ${APP_DIR}/cluster/in-scope/namespaces/store-out-of-scope
  kubectl --context ${CLUSTER_r2_1} -n store-out-of-scope apply -f ${APP_DIR}/cluster/in-scope/namespaces/store-out-of-scope

  # store-out-of-scope resources on the both out-of-scope clusters (CLUSTER_r1_2, and CLUSTER_r2_2)
  # note that CLUSTER_r1_2 is treated here as a primary cluster, and CLUSTER_r2_2 as a secondary one with respect to which workloads
  # are deployed. See discussion in docs
  kubectl --context ${CLUSTER_r1_2} -n store-out-of-scope apply -f ${APP_DIR}/cluster/out-of-scope/namespaces/store-out-of-scope
  kubectl --context ${CLUSTER_r2_2} -n store-out-of-scope apply -f ${APP_DIR}/cluster/out-of-scope/namespaces/store-out-of-scope -l primary_only!=true
}

function enable_multicluster_ingress {
  # membership verification
  echo "gcloud container hub memberships list:"
  gcloud --project=${APP_PROJECT_ID} container hub memberships list
  gcloud --project=${APP_PROJECT_ID} \
    alpha container hub ingress enable \
    --config-membership=projects/${PROJECT_ID}/locations/global/memberships/${CLUSTER_r3_1}
  gcloud --project=${APP_PROJECT_ID} alpha container hub ingress describe
}

function create_mci_and_mcs {
  kubectl --context ${CLUSTER_r3_1} -n istio-system apply -f ${WORKSTATION_SRC_ROOT}/pci-anthos/google-cloud-multi-region/app/mci
}

function describe_crds {
  kubectl --context ${CLUSTER_r3_1} -n istio-system describe multiclusteringress,multiclusterservice
}

# this function is used by infrastructure/initialize-project.tf 
function initialize_project_for_anthos {
  curl --request POST \
    --header "Authorization: Bearer $(gcloud auth print-access-token)" \
    --data '' \
    --silent \
    "https://meshconfig.googleapis.com/v1alpha1/projects/${APP_PROJECT_ID}:initialize"
}