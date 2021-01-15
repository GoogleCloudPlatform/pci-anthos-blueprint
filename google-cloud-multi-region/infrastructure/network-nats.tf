# Outbound NATs are per region collections of google_compute_address, google_compute_router, and google_compute_router_nat

# Region 1

# Addresses
resource "google_compute_address" "r1" {
  name    = "r1"
  project = google_project.network.project_id
  region  = var.subnetworks.r1-1.region
  # google_compute_address depends on the compute API being enabled
  depends_on = [google_project_service.services_app]
}

resource "google_compute_router" "r1" {
  name    = "r1"
  project = google_project.network.project_id
  region  = var.subnetworks.r1-1.region
  network = google_compute_network.multiregion.self_link
}

resource "google_compute_router_nat" "r1" {
  name                               = "r1"
  project                            = google_project.network.project_id
  region                             = var.subnetworks.r1-1.region
  router                             = google_compute_router.r1.name
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.r1.self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Region 2

# Addresses
resource "google_compute_address" "r2" {
  name    = "r2"
  project = google_project.network.project_id
  # todo: getting region from r1-1 instead of r1 is not ideal
  region = var.subnetworks.r2-1.region
  # google_compute_address depends on the compute API being enabled
  depends_on = [google_project_service.services_app]
}

resource "google_compute_router" "r2" {
  name    = "r2"
  project = google_project.network.project_id
  region  = var.subnetworks.r2-1.region
  network = google_compute_network.multiregion.self_link
}

resource "google_compute_router_nat" "r2" {
  name                               = "r2"
  project                            = google_project.network.project_id
  region                             = var.subnetworks.r2-1.region
  router                             = google_compute_router.r2.name
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.r2.self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Region 3

# Addresses
resource "google_compute_address" "r3" {
  name    = "r3"
  project = google_project.network.project_id
  region  = var.subnetworks.r3-1.region
  # google_compute_address depends on the compute API being enabled
  depends_on = [google_project_service.services_app]
}

resource "google_compute_router" "r3" {
  name    = "r3"
  project = google_project.network.project_id
  region  = var.subnetworks.r3-1.region
  network = google_compute_network.multiregion.self_link
}

resource "google_compute_router_nat" "r3" {
  name                               = "r3"
  project                            = google_project.network.project_id
  region                             = var.subnetworks.r3-1.region
  router                             = google_compute_router.r3.name
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.r3.self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
