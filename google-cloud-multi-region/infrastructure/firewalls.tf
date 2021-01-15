resource "google_compute_firewall" "all-pods-and-master-ipv4-cidrs" {
  name          = "all-pods-and-master-ipv4-cidrs"
  project       = google_project.network.project_id
  network       = google_compute_network.multiregion.self_link
  direction     = "INGRESS"
  source_ranges = local.firewall-all-source-ranges
  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "all-control-planes" {
  name          = "all-control-planes"
  project       = google_project.network.project_id
  network       = google_compute_network.multiregion.self_link
  direction     = "INGRESS"
  source_ranges = local.firewall-all-control-planes
  allow {
    protocol = "all"
  }
}

# https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-for-anthos-setup#shared_vpc_deployment
resource "google_compute_firewall" "allow-shared-vpc" {
  name          = "allow-shared-vpc"
  project       = google_project.network.project_id
  network       = google_compute_network.multiregion.self_link
  direction     = "INGRESS"
  source_ranges = local.healthcheck_ip_ranges
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
}
