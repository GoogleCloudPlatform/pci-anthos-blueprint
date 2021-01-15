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

# Running on out-of-scope cluster:
#   "adservice:9555"
#   "cartservice:7070"
#   "currencyservice:7000"
#   "emailservice:5000"
#   "productcatalogservice:3550"
#   "recommendationservice:8080"
#   "shippingservice:50051"
#   "checkoutservice:5050"

# all the firewalls need to be refactored. Currently, the below rule is superfluous considering
# the "all-pods-and-master-ipv4-cidrs" rule

resource "google_compute_firewall" "from-in-scope-to-out-of-scope" {
  name          = "from-in-scope-to-out-of-scope"
  project       = google_project.network.project_id
  network       = google_compute_network.multiregion.self_link
  source_ranges = [var.subnetworks.r1-1.pods_cidr, var.subnetworks.r2-1.pods_cidr]
  target_tags   = [local.out_of_scope_tag]
  allow {
    protocol = "tcp"
    ports    = [9555, 7070, 7000, 5000, 3550, 8080, 50051, 5050]
  }
}
