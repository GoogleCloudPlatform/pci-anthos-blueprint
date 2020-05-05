#!/usr/bin/env bash
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

set -u
source vars.sh


function enable_apis {
  echo "Enabling GCP APIs"
  gcloud services enable \
    container.googleapis.com \
    compute.googleapis.com \
    monitoring.googleapis.com \
    logging.googleapis.com \
    cloudtrace.googleapis.com \
    meshtelemetry.googleapis.com \
    meshconfig.googleapis.com \
    iamcredentials.googleapis.com \
    anthos.googleapis.com \
    gkeconnect.googleapis.com \
    gkehub.googleapis.com \
    cloudresourcemanager.googleapis.com
}

function init_contexts {
  # use cluster1 as in-scope
  init_context ${USER_CLUSTER_1_CONFIG} "in-scope"
  # use cluster2 as out-of-scope
  init_context ${USER_CLUSTER_2_CONFIG} "out-of-scope"
}

function init_context {
  sed -i "s/name: cluster/name: $2/g" $1
  sed -i "s/cluster: cluster/cluster: $2/g" $1
  sed -i "s/name: user/name: $2-user/g" $1
  sed -i "s/user: user/user: $2-user/g" $1
  export KUBECONFIG=$1
  if ! kubectx | grep -q $2 &> /dev/null; then
    kubectx $2=.
  fi
}

function get_packages {
  mkdir -p $TMP_DIR
  pushd $TMP_DIR
  get_kubectx
  get_asm
  popd
}

function get_kubectx {
  if [ ! -d kubectx ]; then
    git clone https://github.com/ahmetb/kubectx kubectx
  fi
  export PATH=$PATH:${PWD}/kubectx
}

function get_asm {
  if [ ! -d istio-${ASM_VERSION} ]; then
    curl -LO https://storage.googleapis.com/gke-release/asm/istio-${ASM_VERSION}-linux-amd64.tar.gz
    curl -LO https://storage.googleapis.com/gke-release/asm/istio-${ASM_VERSION}-linux-amd64.tar.gz.1.sig
    openssl dgst -verify - -signature istio-${ASM_VERSION}-linux-amd64.tar.gz.1.sig istio-${ASM_VERSION}-linux-amd64.tar.gz <<'EOF'
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEWZrGCUaJJr1H8a36sG4UUoXvlXvZ
wQfk16sxprI2gOJ2vFFggdq3ixF2h4qNBt0kI7ciDhgpwS8t+/960IsIgw==
-----END PUBLIC KEY-----
EOF
    tar xzf istio-${ASM_VERSION}-linux-amd64.tar.gz
  fi
}

# do we need this?
function cleanup_namespaces {
  for CTX in in-scope out-of-scope; do
    kubectx $CTX
    kubectl delete namespace store-in-scope &> /dev/null || true
    kubectl delete namespace store-out-of-scope &> /dev/null || true
    kubectl delete namespace istio-system &> /dev/null || true
  done
  sleep 5
}

function create_istio_system_namespace {
  for CTX in in-scope out-of-scope; do
    kubectx $CTX
    kubectl create namespace istio-system
  done
}

function install_ca_certs {
  for CTX in in-scope out-of-scope; do
    kubectx $CTX
    kubectl create secret generic cacerts \
      -n istio-system \
      --from-file=${TMP_DIR}/istio-${ASM_VERSION}/samples/certs/ca-cert.pem \
      --from-file=${TMP_DIR}/istio-${ASM_VERSION}/samples/certs/ca-key.pem \
      --from-file=${TMP_DIR}/istio-${ASM_VERSION}/samples/certs/root-cert.pem \
      --from-file=${TMP_DIR}/istio-${ASM_VERSION}/samples/certs/cert-chain.pem
  done
}

function generate_istio_config_from_template {
  envsubst < ../anthos-service-mesh/istio-operator-in-scope_tmpl.yaml >  ../anthos-service-mesh/istio-operator-${IN_SCOPE_CLUSTER_NAME}.yaml
  envsubst < ../anthos-service-mesh/istio-operator-out-scope_tmpl.yaml >  ../anthos-service-mesh/istio-operator-${OUT_OF_SCOPE_CLUSTER_NAME}.yaml
}

function istioctl_apply {
  for CTX in in-scope out-of-scope; do
    kubectx $CTX
    istioctl manifest apply -f ../anthos-service-mesh/istio-operator-$CTX.yaml \
      --charts $TMP_DIR/istio-${ASM_VERSION}/manifests \
      --set values.global.hub=${ASM_HUB} \
      --set values.global.tag=${ASM_VERSION} \
      --set values.global.imagePullPolicy=Always
  done
}

# Configure cross-cluster service registry. The following command creates a secret in each cluster with the other cluster's
# KUBECONFIG file so it can access (auth) services and endpoints running in that other cluster.
function cross_cluster_service_secret {
  istioctl x create-remote-secret --context=${OUT_OF_SCOPE_CLUSTER_NAME} --name ${OUT_OF_SCOPE_CLUSTER_NAME} | \
    kubectl --context=${IN_SCOPE_CLUSTER_NAME} apply -f -
  istioctl x create-remote-secret --context=${IN_SCOPE_CLUSTER_NAME} --name ${IN_SCOPE_CLUSTER_NAME} | \
    kubectl --context=${OUT_OF_SCOPE_CLUSTER_NAME} apply -f -
}

function generate_ingress_certificates {
  mkdir -p $TMP_DIR/certs
  pushd $TMP_DIR/certs
  kubectx in-scope
  dd if=/dev/urandom of=$HOME/.rnd bs=1000 count=1
  openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=Boutique Inc./CN=exampleboutique.com' -keyout exampleboutique.com.ca.key -out exampleboutique.com.ca.crt
  openssl req -out exampleboutique.com.csr -newkey rsa:2048 -nodes -keyout exampleboutique.com.key -subj "/CN=exampleboutique.com/O=example boutique organization"
  openssl x509 -req -days 365 -CA exampleboutique.com.ca.crt -CAkey exampleboutique.com.ca.key -set_serial 0 -in exampleboutique.com.csr -out exampleboutique.com.crt
  kubectl create -n istio-system secret tls exampleboutique-credential --key=exampleboutique.com.key --cert=exampleboutique.com.crt
  popd
}

function verify_asm {
  for CTX in in-scope out-of-scope; do
    kubectl wait --for condition=ready pod --all -n istio-system --timeout 100s --context $CTX
  done
}

function install_acm {
  for CTX in in-scope out-of-scope; do
    kubectx $CTX
    export CLUSTERNAME=$CTX
    # config dir for in-scope / out-of-scope
    export ACM_POLICYDIR=$ACM_POLICYDIR_ROOT/$CTX
    envsubst < ../anthos-config-management/config-management_tmpl.yaml > ../anthos-config-management/config-management-$CTX.yaml
    kubectl apply -f ../anthos-config-management/config-management-$CTX.yaml
  done
}

function wait_for_gatekeeper {
  for CTX in in-scope out-of-scope; do
    kubectx $CTX
    echo "Waiting for gatekeeper-system namespace..."
    wait_for_namespace gatekeeper-system
    echo "Waiting for gatekeeper-controller-manager..."
    kubectl wait deployments.apps -n gatekeeper-system gatekeeper-controller-manager --for condition=available --timeout=300s
  done
}

function wait_for_namespace {
  count=0
  TIMEOUT=30
  echo "Waiting for namespace $1"
  while true; do
    count=$((count + 1))
    if [ $count -gt $TIMEOUT ] ; then
      echo "Error: namespace creation timeout"
      return 1
    fi
    if kubectl get namespace $1 &> /dev/null; then
      echo "Namespace $1 exists"
      return 0
    fi
    sleep 1
  done
}

function install_asm {
  create_istio_system_namespace
  install_ca_certs
  generate_istio_config_from_template
  istioctl_apply
  generate_ingress_certificates
  cross_cluster_service_secret
  verify_asm
}

function install_store {
  local appdir=../app/store/cluster
  # out-of-scope cluster first
  kubectx out-of-scope
  kubectl apply -f $appdir/out-of-scope/namespaces/store-out-of-scope/ -n store-out-of-scope

  # now in-scope cluster
  kubectx in-scope
  # NOTE: we create the out-of-scope Services in the in-scope cluster to allow k8s to resolve the service names.
  # Those out-of-scope services in the in-scope cluster do not have any associated Deployments or Pods; they
  # are just for name resolution.
  # Istio intercepts the calls to the out-of-scope services, and correctly routes them to the out-of-scope cluster.
  kubectl apply -f $appdir/in-scope/namespaces/store-out-of-scope/ -n store-out-of-scope
  kubectl apply -f $appdir/in-scope/namespaces/store-in-scope/ -n store-in-scope
}


function pci_setup {
  enable_apis
  get_packages
  init_contexts
}

function pci_init {
  export PATH=${TMP_DIR}/istio-${ASM_VERSION}/bin:$PATH
  export PATH=$PATH:${TMP_DIR}/kubectx
  export KUBECONFIG=${USER_CLUSTER_1_CONFIG}:${USER_CLUSTER_2_CONFIG}
}

function pci_install_acm {
  pci_init
  install_acm
  wait_for_gatekeeper
}

function pci_install_asm {
  pci_init
  install_asm
}

function pci_install_store {
  pci_init
  install_store
}
