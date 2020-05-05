#!/usr/bin/env bash -ex
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


function set_up_credentials {
  get_and_set_application_project_id
  gcloud container clusters get-credentials ${IN_SCOPE_CLUSTER_NAME}     --region ${CLUSTER_LOCATION} --project ${APP_PROJECT_ID}
  gcloud container clusters get-credentials ${OUT_OF_SCOPE_CLUSTER_NAME} --region ${CLUSTER_LOCATION} --project ${APP_PROJECT_ID}
  # running delete-context before rename allows for this function to be idempotent
  # The output is suppressed in the next two commands since the output could be misleading in this context
  kubectl config delete-context ${IN_SCOPE_CLUSTER_CTX}     &> /dev/null || true # do not fail if the context does not exist
  kubectl config delete-context ${OUT_OF_SCOPE_CLUSTER_CTX} &> /dev/null || true
  kubectl config rename-context gke_${APP_PROJECT_ID}_${CLUSTER_LOCATION}_${IN_SCOPE_CLUSTER_NAME}     ${IN_SCOPE_CLUSTER_CTX}
  kubectl config rename-context gke_${APP_PROJECT_ID}_${CLUSTER_LOCATION}_${OUT_OF_SCOPE_CLUSTER_NAME} ${OUT_OF_SCOPE_CLUSTER_CTX}
}

function create_istio_system_namespace {
  for cluster in $(kubectl config get-contexts -o=name); do
    kubectl config use-context $cluster
    kubectl apply -f namespaces/istio-system.yml
  done
}

# generates an istio config
# Requires: PROJECT_ID, CLUSTER_LOCATION, CLUSTER_NAME, PROJECT_NUMBER
function generate_istio_config_from_template {
  export PROJECT_ID="${APP_PROJECT_ID}"
  export PROJECT_NUMBER=$(gcloud projects list --filter="PROJECT_ID=${APP_PROJECT_ID}"  --format="value(projectNumber)")
  export CLUSTER_NAME="${IN_SCOPE_CLUSTER_NAME}"
  envsubst < ${SRC_PATH}/anthos-service-mesh/istio-operator_tmpl.yaml >  ${SRC_PATH}/anthos-service-mesh/istio-operator-${IN_SCOPE_CLUSTER_NAME}.yaml
  export CLUSTER_NAME="${OUT_OF_SCOPE_CLUSTER_NAME}"
  envsubst < ${SRC_PATH}/anthos-service-mesh/istio-operator_tmpl.yaml >  ${SRC_PATH}/anthos-service-mesh/istio-operator-${OUT_OF_SCOPE_CLUSTER_NAME}.yaml
}

# See https://cloud.google.com/service-mesh/docs/gke-cluster-setup#setting_credentials_and_permissions
function initialize_project_for_anthos {
  curl --request POST \
    --header "Authorization: Bearer $(gcloud auth print-access-token)" \
    --data '' \
    --silent \
    "https://meshconfig.googleapis.com/v1alpha1/projects/${APP_PROJECT_ID}:initialize"
}

function run_istioctl {
  ${ASM_PATH}/bin/istioctl --context=${IN_SCOPE_CLUSTER_CTX} manifest apply \
    -f ${SRC_PATH}/anthos-service-mesh/istio-operator-${IN_SCOPE_CLUSTER_NAME}.yaml
  ${ASM_PATH}/bin/istioctl --context=${OUT_OF_SCOPE_CLUSTER_CTX} manifest apply \
    -f ${SRC_PATH}/anthos-service-mesh/istio-operator-${OUT_OF_SCOPE_CLUSTER_NAME}.yaml
}

function verify_asm {
  kubectl --context=${IN_SCOPE_CLUSTER_CTX}     -n istio-system get pod
  kubectl --context=${OUT_OF_SCOPE_CLUSTER_CTX} -n istio-system get pod
}

# Configure cross-cluster service registry. The following command creates a secret in each cluster with the other cluster's
# KUBECONFIG file so it can access (auth) services and endpoints running in that other cluster.
function cross_cluster_service_secret {
  ${ASM_PATH}/bin/istioctl x create-remote-secret --context=${OUT_OF_SCOPE_CLUSTER_CTX} --name ${OUT_OF_SCOPE_CLUSTER_NAME} | \
    kubectl --context=${IN_SCOPE_CLUSTER_CTX} apply -f -
  ${ASM_PATH}/bin/istioctl x create-remote-secret --context=${IN_SCOPE_CLUSTER_CTX} --name ${IN_SCOPE_CLUSTER_NAME} | \
    kubectl --context=${OUT_OF_SCOPE_CLUSTER_CTX} apply -f -
}

# Installs the ob application (microservices-demo) to both clusters
# It is required that the namespaces exist. Namespaces are managed via Anthos Config
# Management (see install_anthos_config_sync() and its related repository)
function install_store {
  # populate managed-certificate.yaml from template
  envsubst < ${APP_DIR}/cluster/in-scope/namespaces/frontend/managed-certificate.yaml.tmpl \
           > ${APP_DIR}/cluster/in-scope/namespaces/frontend/managed-certificate.yaml

  # in-scope cluster application resources per namespace
  kubectl --context ${IN_SCOPE_CLUSTER_CTX}     -n paymentservice  apply -f ${APP_DIR}/cluster/in-scope/namespaces/paymentservice
  kubectl --context ${IN_SCOPE_CLUSTER_CTX}     -n checkoutservice apply -f ${APP_DIR}/cluster/in-scope/namespaces/checkoutservice
  kubectl --context ${IN_SCOPE_CLUSTER_CTX}     -n frontend        apply -f ${APP_DIR}/cluster/in-scope/namespaces/frontend

  # store-out-of-scope resources on in-scope cluster
  kubectl --context ${IN_SCOPE_CLUSTER_CTX}     -n store-out-of-scope apply -f ${APP_DIR}/cluster/in-scope/namespaces/store-out-of-scope

  # store-out-of-scope resources on out-of-scope cluster
  kubectl --context ${OUT_OF_SCOPE_CLUSTER_CTX} -n store-out-of-scope apply -f ${APP_DIR}/cluster/out-of-scope/namespaces/store-out-of-scope
}

# Uninstall function added for convenience, not currently called anywhere
function uninstall_store {
  kubectl --context ${IN_SCOPE_CLUSTER_CTX}     -n paymentservice  delete -f ${APP_DIR}/cluster/in-scope/namespaces/paymentservice
  kubectl --context ${IN_SCOPE_CLUSTER_CTX}     -n checkoutservice delete -f ${APP_DIR}/cluster/in-scope/namespaces/checkoutservice
  kubectl --context ${IN_SCOPE_CLUSTER_CTX}     -n frontend        delete -f ${APP_DIR}/cluster/in-scope/namespaces/frontend
  kubectl --context ${IN_SCOPE_CLUSTER_CTX}     -n store-out-of-scope delete -f ${APP_DIR}/cluster/in-scope/namespaces/store-out-of-scope
  kubectl --context ${OUT_OF_SCOPE_CLUSTER_CTX} -n store-out-of-scope delete -f ${APP_DIR}/cluster/out-of-scope/namespaces/store-out-of-scope
}

# waits for a namespace to be created, fails after TIMEOUT seconds
function wait_for_namespace {
  count=0
  TIMEOUT=30
  while true; do
    count=$((count + 1))
    if [ $count -gt $TIMEOUT ] ; then
      echo "Error: namespace creation timeout"
      return 1
    fi
    echo "Waiting for namespace $1"
    kubectl get namespace $1 &>/dev/null
    if [ $? == 0 ] ; then
      echo "Namespace $1 exists"
      return 0
    fi
    sleep 1
  done
}

function install_anthos_config_sync {
  THIS_CONTEXT="$1"
  echo "THIS_CONTEXT: $THIS_CONTEXT"
  kubectl config use-context "${THIS_CONTEXT}" &>/dev/null
  kubectl get namespace config-management-system &>/dev/null
  if [ "$?" != 0 ] ; then
    echo "ADMIN_PROJECT_ID: ${ADMIN_PROJECT_ID}"
    kubectl apply -f "${SRC_PATH}"/anthos-config-management/config-management-operator.yaml
    gcloud secrets --project "${ADMIN_PROJECT_ID}" versions access latest --secret="config-management-deploy-key" > "${SRC_PATH}"/config-management-deploy-key.txt
    kubectl create secret generic git-creds \
      --namespace=config-management-system \
      --from-file=ssh="${SRC_PATH}"/config-management-deploy-key.txt
    # this relies on CLUSTERNAME and POLICYDIR matching $THIS_CONTEXT
    export CLUSTERNAME="${THIS_CONTEXT}"
    export POLICYDIR="${THIS_CONTEXT}"
    echo "Verifying required variables are set:"
    echo "CLUSTERNAME: $CLUSTERNAME"
    echo "POLICYDIR: $POLICYDIR"
    echo "SYNCREPO: $SYNCREPO"
    echo "SYNCBRANCH: $SYNCBRANCH"
    envsubst < "${SRC_PATH}"/anthos-config-management/config-management_tmpl.yaml > "${SRC_PATH}"/anthos-config-management/config-management.yaml
    kubectl apply -f "${SRC_PATH}"/anthos-config-management/config-management.yaml
    # the below two commands are necessary to prepare to be ready for additional changes
    wait_for_namespace gatekeeper-system
    echo "Running: kubectl wait deployments.apps -n gatekeeper-system gatekeeper-controller-manager --for condition=available --timeout=300s"
    kubectl wait deployments.apps -n gatekeeper-system gatekeeper-controller-manager --for condition=available --timeout=600s
  fi
}

# Usage: register_cluster GKE_CLUSTER
# Example: register_cluster in-scope
# Requires a service account of the form ${GKE_CLUSTER}-connect@${APP_PROJECT_ID}.iam.gserviceaccount.com
# The services accounts are created and managed via /infrastructure/anthos-service-accounts.tf
function register_cluster {
  GKE_CLUSTER=$1
  # check for membership existence
  RESPONSE=$(gcloud container hub memberships --project "${APP_PROJECT_ID}" list --filter="Name:${GKE_CLUSTER}")
   # see https://stackoverflow.com/a/229606 for contditional syntax
  if [[ $RESPONSE == *"${GKE_CLUSTER}"* ]] ; then
    echo "${GKE_CLUSTER} membership $1 exists"
  else
    echo "${GKE_CLUSTER} membership does not exist. Creating it now."
    # generate and save a service account key
    gcloud iam service-accounts \
      keys create \
      --project "${APP_PROJECT_ID}" \
      --iam-account ${GKE_CLUSTER}-connect@${APP_PROJECT_ID}.iam.gserviceaccount.com \
      ${GKE_CLUSTER}-connect@${APP_PROJECT_ID}.iam.gserviceaccount.com.json
    # create membership
    gcloud container hub memberships register "${GKE_CLUSTER}" \
       --project="${APP_PROJECT_ID}" \
       --gke-cluster="${CLUSTER_LOCATION}/${GKE_CLUSTER}" \
       --service-account-key-file="${GKE_CLUSTER}-connect@${APP_PROJECT_ID}.iam.gserviceaccount.com.json"
    fi
}

function get_and_set_application_project_id {
  pushd "${SRC_PATH}"/infrastructure
  export APP_PROJECT_ID=$(terraform output -json|jq -r .app1_project_raw_id.value)
  echo "APP_PROJECT_ID: ${APP_PROJECT_ID}"
  popd
}

function install_acm_two_clusters {
  set_up_credentials
  install_anthos_config_sync in-scope
  install_anthos_config_sync out-of-scope
}

function install_asm {
  set_up_credentials
  create_istio_system_namespace
  generate_istio_config_from_template
  initialize_project_for_anthos
  run_istioctl
  verify_asm
  cross_cluster_service_secret
  register_cluster in-scope
  register_cluster out-of-scope
}

function install_application {
  set_up_credentials
  install_store
}
