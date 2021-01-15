resource "google_compute_subnetwork" "r1-1" {
  name                     = var.subnetworks.r1-1.name
  project                  = google_project.network.project_id
  region                   = var.subnetworks.r1-1.region
  network                  = google_compute_network.multiregion.self_link
  private_ip_google_access = true
  ip_cidr_range            = var.subnetworks.r1-1.instance_cidr
  secondary_ip_range {
    range_name    = "r1-1-pods"
    ip_cidr_range = var.subnetworks.r1-1.pods_cidr
  }
  secondary_ip_range {
    range_name    = "r1-1-services"
    ip_cidr_range = var.subnetworks.r1-1.services_cidr
  }
}

# output "sn-r1-1" {
#   value = google_compute_subnetwork.r1-1
# }

resource "google_compute_subnetwork" "r1-2" {
  name                     = var.subnetworks.r1-2.name
  project                  = google_project.network.project_id
  region                   = var.subnetworks.r1-2.region
  network                  = google_compute_network.multiregion.self_link
  private_ip_google_access = true
  ip_cidr_range            = var.subnetworks.r1-2.instance_cidr
  secondary_ip_range {
    range_name    = "r1-2-pods"
    ip_cidr_range = var.subnetworks.r1-2.pods_cidr
  }
  secondary_ip_range {
    range_name    = "r1-2-services"
    ip_cidr_range = var.subnetworks.r1-2.services_cidr
  }
}

resource "google_compute_subnetwork" "r2-1" {
  name                     = var.subnetworks.r2-1.name
  project                  = google_project.network.project_id
  region                   = var.subnetworks.r2-1.region
  network                  = google_compute_network.multiregion.self_link
  private_ip_google_access = true
  ip_cidr_range            = var.subnetworks.r2-1.instance_cidr
  secondary_ip_range {
    range_name    = "r2-1-pods"
    ip_cidr_range = var.subnetworks.r2-1.pods_cidr
  }
  secondary_ip_range {
    range_name    = "r2-1-services"
    ip_cidr_range = var.subnetworks.r2-1.services_cidr
  }
}

resource "google_compute_subnetwork" "r2-2" {
  name                     = var.subnetworks.r2-2.name
  project                  = google_project.network.project_id
  region                   = var.subnetworks.r2-2.region
  network                  = google_compute_network.multiregion.self_link
  private_ip_google_access = true
  ip_cidr_range            = var.subnetworks.r2-2.instance_cidr
  secondary_ip_range {
    range_name    = "r2-2-pods"
    ip_cidr_range = var.subnetworks.r2-2.pods_cidr
  }
  secondary_ip_range {
    range_name    = "r2-2-services"
    ip_cidr_range = var.subnetworks.r2-2.services_cidr
  }
}

resource "google_compute_subnetwork" "r3-1" {
  name                     = var.subnetworks.r3-1.name
  project                  = google_project.network.project_id
  region                   = var.subnetworks.r3-1.region
  network                  = google_compute_network.multiregion.self_link
  private_ip_google_access = true
  ip_cidr_range            = var.subnetworks.r3-1.instance_cidr
  secondary_ip_range {
    range_name    = "r3-1-pods"
    ip_cidr_range = var.subnetworks.r3-1.pods_cidr
  }
  secondary_ip_range {
    range_name    = "r3-1-services"
    ip_cidr_range = var.subnetworks.r3-1.services_cidr
  }
}

