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

# Creating the network
# https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-shared-vpc#creating_a_network_and_two_subnets
resource "google_compute_network" "shared-vpc" {
  name                    = var.shared_vpc_name
  project                 = google_project.network.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "in-scope" {
  name                     = local.in_scope_subnet_name
  project                  = google_project.network.project_id
  region                   = var.region
  network                  = google_compute_network.shared-vpc.self_link
  private_ip_google_access = true
  ip_cidr_range            = local.in_scope_subnet_cidr
  secondary_ip_range {
    range_name    = local.in_scope_pod_ip_range_name
    ip_cidr_range = local.in_scope_pod_ip_cidr_range
  }
  secondary_ip_range {
    range_name    = local.in_scope_services_ip_range_name
    ip_cidr_range = local.in_scope_services_ip_cidr_range
  }
}

resource "google_compute_subnetwork" "out-of-scope" {
  name                     = local.out_of_scope_subnet_name
  project                  = google_project.network.project_id
  region                   = var.region
  network                  = google_compute_network.shared-vpc.self_link
  private_ip_google_access = true
  ip_cidr_range            = local.out_of_scope_subnet_cidr
  secondary_ip_range {
    range_name    = local.out_of_scope_pod_ip_range_name
    ip_cidr_range = local.out_of_scope_pod_ip_cidr_range
  }
  secondary_ip_range {
    range_name    = local.out_of_scope_services_ip_range_name
    ip_cidr_range = local.out_of_scope_services_ip_cidr_range
  }
}


# Enabling shared vpc
# https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-shared-vpc#enabling_shared_vpc_and_granting_roles
resource "google_compute_shared_vpc_host_project" "network" {
  project = google_project.network.project_id
}
resource "google_compute_shared_vpc_service_project" "app1" {
  host_project    = google_project.network.project_id
  service_project = google_project.app1.project_id
}
# resource "google_compute_shared_vpc_service_project" "out-of-scope" {
#   host_project    = google_project.network.project_id
#   service_project = google_project.out_of_scope.project_id
# }

# setting IAM policy
## in-scope
data "google_iam_policy" "in-scope-policy" {
  binding {
    role = "roles/compute.networkUser"
    members = [
      "serviceAccount:${google_project.app1.number}@cloudservices.gserviceaccount.com",
    ]
  }
  binding {
    role = "roles/compute.networkUser"
    members = [
      "serviceAccount:service-${google_project.app1.number}@container-engine-robot.iam.gserviceaccount.com",
    ]
  }
}
resource "google_compute_subnetwork_iam_policy" "in-scope" {
  project     = google_project.network.project_id
  region      = var.region
  subnetwork  = google_compute_subnetwork.in-scope.name
  policy_data = data.google_iam_policy.in-scope-policy.policy_data
}

resource "google_compute_subnetwork_iam_policy" "out-of-scope" {
  project    = google_project.network.project_id
  region     = var.region
  subnetwork = google_compute_subnetwork.out-of-scope.name
  # todo: fix names.
  policy_data = data.google_iam_policy.in-scope-policy.policy_data
}

# outbound NAT for private clusters
resource "google_compute_router" "router" {
  name    = "router"
  project = google_project.network.project_id
  region  = var.region
  network = google_compute_network.shared-vpc.self_link
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat-all"
  project                            = google_project.network.project_id
  region                             = var.region
  router                             = google_compute_router.router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.in-scope.self_link
    source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE"]
  }

  subnetwork {
    name                    = google_compute_subnetwork.out-of-scope.self_link
    source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE"]
  }
}
