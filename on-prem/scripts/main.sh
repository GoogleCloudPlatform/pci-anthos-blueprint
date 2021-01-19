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

  if [ ! -d asm-packages ]; then
    git clone https://github.com/GoogleCloudPlatform/anthos-service-mesh-packages.git asm-packages
    git -C asm-packages checkout ${ASM_PACKAGES_BRANCH}
  fi
}

function create_istio_system_namespace {
  for CTX in in-scope out-of-scope; do
    kubectx $CTX
    kubectl create namespace istio-system &> /dev/null || true
    kubectl label namespace istio-system name=istio-system
    kubectl label namespace istio-system topology.istio.io/network=${CTX}-network
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
  envsubst < ../anthos-service-mesh/istiod-service_tmpl.yaml >  ../anthos-service-mesh/istiod-service.yaml
  for CTX in in-scope out-of-scope; do
    envsubst < ../anthos-service-mesh/istio-overlay-${CTX}_tmpl.yaml >  ../anthos-service-mesh/istio-overlay-${CTX}.yaml
  done
}

function istioctl_install {
  for CTX in in-scope out-of-scope; do
    kubectx $CTX
	  istioctl install -y \
      --set profile=asm-multicloud \
      --set revision=${ASM_REVISION_LABEL} \
      -f ../anthos-service-mesh/istio-overlay-$CTX.yaml \
      -f ${TMP_DIR}/asm-packages/asm/istio/options/cni-onprem.yaml

    # add validating webhook
    kubectl apply -f ../anthos-service-mesh/istiod-service.yaml
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

# testing
function remove_asm {
  for CTX in in-scope out-of-scope; do
    kubectx $CTX
    kubectl delete istiooperator installed-state-${ASM_REVISION_LABEL} -n istio-system
    kubectl delete ns istio-system
  done
}

# testing
function remove_store {
  local appdir=../app/store/cluster
  kubectx out-of-scope
  kubectl delete -f $appdir/out-of-scope/namespaces/store-out-of-scope/ -n store-out-of-scope
  kubectx in-scope
  kubectl delete -f $appdir/in-scope/namespaces/store-out-of-scope/ -n store-out-of-scope
  kubectl delete -f $appdir/in-scope/namespaces/store-in-scope/ -n store-in-scope
}

function install_asm {
  create_istio_system_namespace
  install_ca_certs
  generate_istio_config_from_template
  istioctl_install
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
