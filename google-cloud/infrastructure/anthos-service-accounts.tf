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

# Create service accounts used for connecting the GKE clusters with an Anthos Environ
# https://cloud.google.com/anthos/multicluster-management/connect/registering-a-cluster
# These service accounts are used in the register_cluster function in scripts/main.sh
resource "google_service_account" "cluster-with-environ-in-scope" {
  project      = google_project.app1.project_id
  account_id   = "in-scope-connect"
  display_name = "in-scope-connect"
}

resource "google_service_account" "cluster-with-environ-out-of-scope" {
  project      = google_project.app1.project_id
  account_id   = "out-of-scope-connect"
  display_name = "out-of-scope-connect"
}

resource "google_project_iam_binding" "project" {
  project = google_project.app1.project_id
  role    = "roles/gkehub.connect"

  members = [
    "serviceAccount:${google_service_account.cluster-with-environ-in-scope.email}",
    "serviceAccount:${google_service_account.cluster-with-environ-out-of-scope.email}",
  ]
}
