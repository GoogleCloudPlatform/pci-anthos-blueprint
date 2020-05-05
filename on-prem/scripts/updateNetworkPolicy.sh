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

set -e

if [ -z "$1" ]
  then
    echo "Please supply the out-of-scope ingress VIP"
    exit 1
fi
NETWORK_POLICY=../demo/config-management/in-scope/namespaces/store-in-scope/network-policy.yaml
# set the actual value for the out-of-scope ingress VIP
sed -i "s/<OUT_OF_SCOPE_ISTIO_INGRESS_IP>/$1/g" $NETWORK_POLICY
