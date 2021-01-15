# config cluster
resource "google_container_cluster" "r3_1" {
  provider                 = google-beta
  name                     = var.subnetworks.r3-1.name
  location                 = "${var.subnetworks.r3-1.region}-a"
  project                  = google_project.app.project_id
  network                  = google_compute_network.multiregion.self_link
  subnetwork               = google_compute_subnetwork.r3-1.id
  remove_default_node_pool = true
  initial_node_count       = 3
  networking_mode          = "VPC_NATIVE"
  resource_labels = {
    mesh_id = local.mesh_id
  }
  workload_identity_config {
    identity_namespace = "${google_project.app.project_id}.svc.id.goog"
  }
  ip_allocation_policy {
    cluster_secondary_range_name  = var.subnetworks.r3-1.pods_range_name
    services_secondary_range_name = var.subnetworks.r3-1.services_range_name
  }
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.subnetworks.r3-1.control_plane_cidr
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = var.subnetworks.r3-1.control_plane_authorized_networks_cidr
    }
  }
}

resource "google_container_node_pool" "r3_1" {
  provider           = google-beta
  location           = google_container_cluster.r3_1.location
  initial_node_count = 3
  cluster            = google_container_cluster.r3_1.name
  project            = google_container_cluster.r3_1.project
  node_config {
    machine_type = local.cluster-ingress-machine-type
    oauth_scopes = local.config_cluster_node_pool_oauth_scopes
    tags         = [local.config_cluster_tag]
  }
}


# output "cluster_ingress" {
#   value = google_container_cluster.r3-1.name
# }
# output "cluster_ingress_location" {
#   value = google_container_cluster.r3-1.location
# }
