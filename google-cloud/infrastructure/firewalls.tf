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

# https://cloud.google.com/service-mesh/docs/private-cluster-open-port
resource "google_compute_firewall" "in-scope-asm-auto-sidecar-injection" {
  name          = "in-scope-asm-auto-sidecar-injection"
  project       = google_project.network.project_id
  network       = google_compute_network.shared-vpc.name
  source_ranges = [local.in_scope_master_ipv4_cidr_block]
  target_tags   = [local.in_scope_network_tag]
  allow {
    protocol = "tcp"
    ports    = [15017]
  }
}
resource "google_compute_firewall" "out-of-scope-asm-auto-sidecar-injection" {
  name          = "out-of-scope-asm-auto-sidecar-injection"
  project       = google_project.network.project_id
  network       = google_compute_network.shared-vpc.name
  source_ranges = [local.out_of_scope_master_ipv4_cidr_block]
  target_tags   = [local.out_of_scope_network_tag]
  allow {
    protocol = "tcp"
    ports    = [15017]
  }
}

# required for the policy controller admission webhook
resource "google_compute_firewall" "in-scope-policy-controller-admission-webhook" {
  name          = "in-scope-policy-controller-admission-webhook"
  project       = google_project.network.project_id
  network       = google_compute_network.shared-vpc.name
  source_ranges = [local.in_scope_master_ipv4_cidr_block]
  target_tags   = [local.in_scope_network_tag]
  allow {
    protocol = "tcp"
    ports    = [8443]
  }
  # Uncomment to enable firewall logging
  # log_config {
  #   metadata = "INCLUDE_ALL_METADATA"
  # }
}

resource "google_compute_firewall" "out-of-scope-policy-controller-admission-webhook" {
  name          = "out-of-scope-policy-controller-admission-webhook"
  project       = google_project.network.project_id
  network       = google_compute_network.shared-vpc.name
  source_ranges = [local.out_of_scope_master_ipv4_cidr_block]
  target_tags   = [local.out_of_scope_network_tag]
  allow {
    protocol = "tcp"
    ports    = [8443]
  }
  # Uncomment to enable firewall logging
  # log_config {
  #   metadata = "INCLUDE_ALL_METADATA"
  # }
}

# allow ingress from health check sources
resource "google_compute_firewall" "allow-healthcheck-ingress" {
  name          = "allow-healthcheck-ingress"
  project       = google_project.network.project_id
  network       = google_compute_network.shared-vpc.name
  direction     = "INGRESS"
  source_ranges = local.healthcheck_ip_ranges
  allow {
    protocol = "tcp"
    ports    = [80, 443]
  }
}

# default deny all egress
# note lower priority than other rules to enable allow rules below 
resource "google_compute_firewall" "default-deny-all-egress" {
  name               = "default-deny-all-egress"
  project            = google_project.network.project_id
  network            = google_compute_network.shared-vpc.name
  priority           = 2000
  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]
  deny {
    protocol = "all"
  }
  # Uncomment to enable firewall logging
  # log_config {
  #   metadata = "INCLUDE_ALL_METADATA"
  # }
}

resource "google_compute_firewall" "allow-healthcheck-egress" {
  name    = "allow-healthcheck-egress"
  project = google_project.network.project_id
  network = google_compute_network.shared-vpc.name
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  direction          = "EGRESS"
  destination_ranges = local.healthcheck_ip_ranges
}

# allow traffic to the restricted Google APIs VIP
resource "google_compute_firewall" "allow-google-apis-egress" {
  name               = "allow-google-apis-egress"
  project            = google_project.network.project_id
  network            = google_compute_network.shared-vpc.name
  direction          = "EGRESS"
  destination_ranges = local.google_apis_ip_ranges
  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "allow-internal-in-scope" {
  name               = "allow-internal-in-scope"
  project            = google_project.network.project_id
  network            = google_compute_network.shared-vpc.name
  direction          = "EGRESS"
  destination_ranges = [local.in_scope_subnet_cidr, local.in_scope_pod_ip_cidr_range, local.in_scope_services_ip_cidr_range, local.in_scope_master_ipv4_cidr_block]
  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "allow-internal-out-of-scope" {
  name               = "allow-internal-out-of-scope"
  project            = google_project.network.project_id
  network            = google_compute_network.shared-vpc.name
  direction          = "EGRESS"
  destination_ranges = [local.out_of_scope_subnet_cidr, local.out_of_scope_pod_ip_cidr_range, local.out_of_scope_services_ip_cidr_range, local.out_of_scope_master_ipv4_cidr_block]
  allow {
    protocol = "all"
  }
}

# https://cloud.google.com/load-balancing/docs/health-check-concepts#ip-ranges
resource "google_compute_firewall" "allow-egress-health-checks" {
  name               = "allow-egress-health-checks"
  project            = google_project.network.project_id
  network            = google_compute_network.shared-vpc.name
  direction          = "EGRESS"
  destination_ranges = local.network_load_balancing_probe_source_ip_ranges
  allow {
    protocol = "tcp"
  }
}

resource "google_compute_firewall" "allow-egress-cloud-regional-ipv4-ranges" {
  name               = "allow-egress-cloud-regional-ipv4-ranges"
  project            = google_project.network.project_id
  network            = google_compute_network.shared-vpc.name
  direction          = "EGRESS"
  destination_ranges = local.cloud_regional_ipv4_ranges
  allow {
    protocol = "tcp"
    ports    = [443]
  }
}

resource "google_compute_firewall" "allow-egress-google-ipv4-ranges" {
  name               = "allow-egress-google-ipv4-ranges"
  project            = google_project.network.project_id
  network            = google_compute_network.shared-vpc.name
  direction          = "EGRESS"
  destination_ranges = local.google_ipv4_ranges
  allow {
    protocol = "tcp"
    ports    = [443]
  }
}

resource "google_compute_firewall" "allow-egress-5355-udp" {
  name               = "allow-egress-5355-udp"
  project            = google_project.network.project_id
  network            = google_compute_network.shared-vpc.name
  direction          = "EGRESS"
  destination_ranges = local.port_5355_udp_allow_list
  allow {
    protocol = "udp"
    ports    = [5355]
  }
}

resource "google_compute_firewall" "allow-egress-github-port-22" {
  name               = "allow-egress-github-port-22"
  project            = google_project.network.project_id
  network            = google_compute_network.shared-vpc.name
  direction          = "EGRESS"
  destination_ranges = local.github_git_ip_ranges
  allow {
    protocol = "tcp"
    ports    = [22]
  }
}
