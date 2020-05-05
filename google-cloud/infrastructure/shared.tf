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

provider "google" {
  version = "~> 3.40.0"
  region  = var.region
}
provider "google-beta" {
  version = "~> 3.40.0"
  region  = var.region
}

variable "billing_account" {
  description = "The ID of the associated billing account"
  default     = ""
}
variable "infrastructure_folder_id" {
  description = "The ID of the folder in which projects should be created"
}
variable "project_prefix" {
  description = "Segment to prefix all project names with."
}
variable "region" {}
variable "shared_vpc_name" {
  default     = "shared-vpc"
  description = "The name of the Shared VPC network"
}

locals {
  project_network = "${var.project_prefix}-network"
  project_app1    = "${var.project_prefix}-app"
}

variable "acm_syncbranch" {}
variable "acm_syncrepo" {}

variable "source_path" {
  description = "path to this source code"
  default     = "/workspace/google-cloud"
}
variable "application_services" {
  type = list(string)
  default = [
    "container.googleapis.com",
    "compute.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "meshca.googleapis.com",
    "meshtelemetry.googleapis.com",
    "meshconfig.googleapis.com",
    "meshca.googleapis.com",
    "meshtelemetry.googleapis.com",
    "iamcredentials.googleapis.com",
    "anthos.googleapis.com",
    "gkeconnect.googleapis.com",
    "gkehub.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudtrace.googleapis.com",
    "monitoring.googleapis.com"
  ]
}
variable "api_enabled_services_project_network" {
  type = list(string)
  default = [
    "container.googleapis.com",
    "dns.googleapis.com",
    "compute.googleapis.com"
  ]
}
variable "frontend_hostname" {
  default = "store"
}
variable "frontend_zone_dns_name" {
  default = "mycompany.com"
}
locals {

  # ASM specific
  mesh_id = "proj-${google_project.app1.number}"

  # in-scope network details
  in_scope_subnet_name = "in-scope"
  in_scope_subnet_cidr = "10.0.4.0/22"

  in_scope_pod_ip_range_name = "in-scope-pod-cidr"
  in_scope_pod_ip_cidr_range = "10.4.0.0/14"

  in_scope_services_ip_range_name = "in-scope-services-cidr"
  in_scope_services_ip_cidr_range = "10.0.32.0/20"

  in_scope_master_ipv4_cidr_block                           = "10.10.11.0/28"
  in_scope_master_authorized_networks_config_1_display_name = "all"
  in_scope_master_authorized_networks_config_1_cidr_block   = "0.0.0.0/0"

  # in-scope cluster details
  in_scope_cluster_name                 = "in-scope"
  in_scope_node_pool_initial_node_count = 1
  in_scope_cluster_release_channel      = "REGULAR"

  in_scope_node_pool_autoscaling_min_node_count = 2
  in_scope_node_pool_autoscaling_max_node_count = 5

  in_scope_node_pool_machine_type = "e2-standard-4"
  in_scope_network_tag            = "in-scope"

  in_scope_node_pool_oauth_scopes = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/trace.append",
    "https://www.googleapis.com/auth/cloud_debugger",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/service.management.readonly"
  ]
  in_scope_node_pool_auto_repair     = true
  in_scope_node_pool_auto_upgrade    = true
  in_scope_node_pool_max_surge       = 1
  in_scope_node_pool_max_unavailable = 0

  # out-of-scope network details
  out_of_scope_subnet_name = "out-of-scope"
  out_of_scope_subnet_cidr = "172.16.4.0/22"

  out_of_scope_pod_ip_range_name = "out-of-scope-pod-cidr"
  out_of_scope_pod_ip_cidr_range = "172.20.0.0/14"

  out_of_scope_services_ip_range_name = "out-of-scope-services-cidr"
  out_of_scope_services_ip_cidr_range = "172.16.16.0/20"

  out_of_scope_master_ipv4_cidr_block                           = "10.10.12.0/28"
  out_of_scope_master_authorized_networks_config_1_display_name = "all"
  out_of_scope_master_authorized_networks_config_1_cidr_block   = "0.0.0.0/0"

  # out-of-scope cluster details
  out_of_scope_cluster_name                 = "out-of-scope"
  out_of_scope_node_pool_initial_node_count = 1
  out_of_scope_cluster_release_channel      = "REGULAR"

  out_of_scope_node_pool_autoscaling_min_node_count = 2
  out_of_scope_node_pool_autoscaling_max_node_count = 5
  out_of_scope_node_pool_machine_type               = "e2-standard-4"
  out_of_scope_network_tag                          = "out-of-scope"

  out_of_scope_node_pool_oauth_scopes = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/trace.append",
    "https://www.googleapis.com/auth/cloud_debugger",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/service.management.readonly"
  ]
  out_of_scope_node_pool_auto_repair     = true
  out_of_scope_node_pool_auto_upgrade    = true
  out_of_scope_node_pool_max_surge       = 1
  out_of_scope_node_pool_max_unavailable = 0

  frontend_external_address_name = "frontend-ext-ip"
  regular_service_perimeter_restricted_services = [
    "cloudtrace.googleapis.com",
    "monitoring.googleapis.com"
  ]
}

# Begin section of firewall related data and locals
# See https://cloud.google.com/compute/docs/faq#find_ip_range
data "http" "cloud-json" {
  url = "https://www.gstatic.com/ipranges/cloud.json"
}
data "http" "goog-json" {
  url = "https://www.gstatic.com/ipranges/goog.json"
}

locals {
  cloud_prefixes             = jsondecode(data.http.cloud-json.body).prefixes
  cloud_regional_ipv4_ranges = [for prefix in local.cloud_prefixes : prefix.ipv4Prefix if prefix.scope == var.region]

  goog_prefixes = jsondecode(data.http.goog-json.body).prefixes
  # populates a list of IPv4 ranges, adding empty strings for elements that do not have a .ipv4Prefix value
  list_with_empty_strings = [for prefix in local.goog_prefixes : try(prefix.ipv4Prefix, "")]
  # strips the empty strings from list_with_empty_strings
  google_ipv4_ranges = [for item in local.list_with_empty_strings : item if item != ""]
}


locals {
  network_load_balancing_probe_source_ip_ranges = [
    "35.191.0.0/16",
    "209.85.152.0/22",
    "209.85.204.0/22"
  ]
  port_5355_udp_allow_list = ["224.0.0.252/32"]
  healthcheck_ip_ranges    = ["130.211.0.0/22", "35.191.0.0/16"]
  google_apis_ip_ranges    = ["199.36.153.4/30"]

  # See https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/about-githubs-ip-addresses
  github_git_ip_ranges = [
    "192.30.252.0/22",
    "185.199.108.0/22",
    "140.82.112.0/20",
    "13.114.40.48/32",
    "52.192.72.89/32",
    "52.69.186.44/32",
    "15.164.81.167/32",
    "52.78.231.108/32",
    "13.234.176.102/32",
    "13.234.210.38/32",
    "13.229.188.59/32",
    "13.250.177.223/32",
    "52.74.223.119/32",
    "13.236.229.21/32",
    "13.237.44.5/32",
    "52.64.108.95/32",
    "18.228.52.138/32",
    "18.228.67.229/32",
    "18.231.5.6/32",
    "18.181.13.223/32",
    "54.238.117.237/32",
    "54.168.17.15/32",
    "3.34.26.58/32",
    "13.125.114.27/32",
    "3.7.2.84/32",
    "3.6.106.81/32",
    "18.140.96.234/32",
    "18.141.90.153/32",
    "18.138.202.180/32",
    "52.63.152.235/32",
    "3.105.147.174/32",
    "3.106.158.203/32",
    "54.233.131.104/32",
    "18.231.104.233/32",
    "18.228.167.86/32"
  ]
}
# End section of firewall related data and locals
