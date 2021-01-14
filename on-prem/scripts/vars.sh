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

# kubeconfig for the in-scope cluster
export USER_CLUSTER_1_CONFIG=<PATH_TO_IN_SCOPE_CLUSTER_KUBECONFIG>
# kubeconfig for the out-of-scope cluster
export USER_CLUSTER_2_CONFIG=<PATH_TO_OUT_OF_SCOPE_CLUSTER_KUBECONFIG>

# VIP configured on load balancer for the in-scope cluster
export IN_SCOPE_ISTIO_INGRESS_IP=<IN_SCOPE_INGRESS_VIP>
# VIP configured on load balancer for the out-of-scope cluster
export OUT_OF_SCOPE_ISTIO_INGRESS_IP=<OUT_OF_SCOPE_INGRESS_VIP>

# Anthos Config Management syncs cluster configs from this repo
# some accessible repo that you own e.g. https://github.com/someuser/anthos-onprem-pci-acm
export ACM_SYNCREPO=<YOUR_ACM_REPO>
# ACM will sync from this branch
export ACM_SYNCBRANCH="master"
# assumes the repo is publicly accessible
export ACM_SECRETTYPE="none"
# the directory within the repo that contains the configs.
export ACM_POLICYDIR_ROOT="demo/config-management"

# downloaded packages stored here
export TMP_DIR=~/pci-anthos-op

# Names to use for the in-scope and out-of-scope clusters
export IN_SCOPE_CLUSTER_NAME=in-scope
export OUT_OF_SCOPE_CLUSTER_NAME=out-of-scope

# ASM/Istio details
export ASM_VERSION=1.7.3-asm.6
export ASM_REVISION_LABEL=asm-173-6
export ASM_PACKAGES_BRANCH="release-1.7-asm"
