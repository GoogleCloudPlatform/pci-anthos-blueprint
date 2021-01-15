# Region 1

resource "google_container_cluster" "r1_1" {
  provider                 = google-beta
  name                     = var.subnetworks.r1-1.name
  location                 = "${var.subnetworks.r1-1.region}-a"
  project                  = google_project.app.project_id
  network                  = google_compute_network.multiregion.self_link
  subnetwork               = google_compute_subnetwork.r1-1.id
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
    cluster_secondary_range_name  = var.subnetworks.r1-1.pods_range_name
    services_secondary_range_name = var.subnetworks.r1-1.services_range_name
  }
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.subnetworks.r1-1.control_plane_cidr
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = var.subnetworks.r1-1.control_plane_authorized_networks_cidr
    }
  }
}

output "r1_1" {
  value = google_container_cluster.r1_1.name
}
output "r1_2" {
  value = google_container_cluster.r1_2.name
}
output "r2_1" {
  value = google_container_cluster.r2_1.name
}
output "r2_2" {
  value = google_container_cluster.r2_2.name
}
output "r3_1" {
  value = google_container_cluster.r3_1.name
}

output "r1_1_location" {
  value = google_container_cluster.r1_1.location
}
output "r1_2_location" {
  value = google_container_cluster.r1_2.location
}
output "r2_1_location" {
  value = google_container_cluster.r2_1.location
}
output "r2_2_location" {
  value = google_container_cluster.r2_2.location
}
output "r3_1_location" {
  value = google_container_cluster.r3_1.location
}


resource "google_container_node_pool" "r1_1" {
  provider           = google-beta
  location           = google_container_cluster.r1_1.location
  initial_node_count = 3
  cluster            = google_container_cluster.r1_1.name
  project            = google_container_cluster.r1_1.project
  node_config {
    machine_type = local.cluster-1-machine-type
    oauth_scopes = local.in_scope_node_pool_oauth_scopes
    tags         = [local.in_scope_tag]
  }
}

resource "google_container_cluster" "r1_2" {
  provider                 = google-beta
  name                     = var.subnetworks.r1-2.name
  location                 = "${var.subnetworks.r1-2.region}-a"
  project                  = google_project.app.project_id
  network                  = google_compute_network.multiregion.self_link
  subnetwork               = google_compute_subnetwork.r1-2.id
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
    cluster_secondary_range_name  = var.subnetworks.r1-2.pods_range_name
    services_secondary_range_name = var.subnetworks.r1-2.services_range_name
  }
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.subnetworks.r1-2.control_plane_cidr
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = var.subnetworks.r1-2.control_plane_authorized_networks_cidr
    }
  }
}

resource "google_container_node_pool" "r1_2" {
  provider           = google-beta
  location           = google_container_cluster.r1_2.location
  initial_node_count = 3
  cluster            = google_container_cluster.r1_2.name
  project            = google_container_cluster.r1_2.project
  node_config {
    machine_type = local.cluster-1-machine-type
    oauth_scopes = local.out_of_scope_node_pool_oauth_scopes
    tags         = [local.out_of_scope_tag]
  }
}

# Region 2

resource "google_container_cluster" "r2_1" {
  provider                 = google-beta
  name                     = var.subnetworks.r2-1.name
  location                 = "${var.subnetworks.r2-1.region}-a"
  project                  = google_project.app.project_id
  network                  = google_compute_network.multiregion.self_link
  subnetwork               = google_compute_subnetwork.r2-1.id
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
    cluster_secondary_range_name  = var.subnetworks.r2-1.pods_range_name
    services_secondary_range_name = var.subnetworks.r2-1.services_range_name
  }
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.subnetworks.r2-1.control_plane_cidr
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = var.subnetworks.r2-1.control_plane_authorized_networks_cidr
    }
  }
}

resource "google_container_node_pool" "r2_1" {
  provider           = google-beta
  location           = google_container_cluster.r2_1.location
  initial_node_count = 3
  cluster            = google_container_cluster.r2_1.name
  project            = google_container_cluster.r2_1.project
  node_config {
    machine_type = local.cluster-1-machine-type
    oauth_scopes = local.in_scope_node_pool_oauth_scopes
    tags         = [local.in_scope_tag]
  }
}

resource "google_container_cluster" "r2_2" {
  provider                 = google-beta
  name                     = var.subnetworks.r2-2.name
  location                 = "${var.subnetworks.r2-2.region}-a"
  project                  = google_project.app.project_id
  network                  = google_compute_network.multiregion.self_link
  subnetwork               = google_compute_subnetwork.r2-2.id
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
    cluster_secondary_range_name  = var.subnetworks.r2-2.pods_range_name
    services_secondary_range_name = var.subnetworks.r2-2.services_range_name
  }
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.subnetworks.r2-2.control_plane_cidr
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = var.subnetworks.r2-2.control_plane_authorized_networks_cidr
    }
  }
}

resource "google_container_node_pool" "r2_2" {
  provider           = google-beta
  location           = google_container_cluster.r2_2.location
  initial_node_count = 3
  cluster            = google_container_cluster.r2_2.name
  project            = google_container_cluster.r2_2.project
  node_config {
    machine_type = local.cluster-1-machine-type
    oauth_scopes = local.out_of_scope_node_pool_oauth_scopes
    tags         = [local.out_of_scope_tag]
  }
}

