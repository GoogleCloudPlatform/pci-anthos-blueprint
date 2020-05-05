/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# presently, using the scripted install method, there is no obvious way to allow
# terraform to track the state of whether or not acm is installed. The function
# install_acm_two_clusters checks first itself before triggering an install
resource "null_resource" "ensure_acm_installed" {
  depends_on = [google_container_node_pool.in_scope_node_pool, google_container_node_pool.out_of_scope_node_pool]
  triggers = {
    always_run = uuid()
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      IN_SCOPE_CLUSTER_NAME     = local.in_scope_cluster_name
      OUT_OF_SCOPE_CLUSTER_NAME = local.out_of_scope_cluster_name
      IN_SCOPE_CLUSTER_CTX      = local.in_scope_cluster_name
      OUT_OF_SCOPE_CLUSTER_CTX  = local.out_of_scope_cluster_name
      CLUSTER_LOCATION          = var.region
      APP_PROJECT_ID            = local.project_app1
      SYNCBRANCH                = var.acm_syncbranch
      SYNCREPO                  = var.acm_syncrepo
    }
    command = "source ${var.source_path}/scripts/main.sh ; install_acm_two_clusters"
  }
}
