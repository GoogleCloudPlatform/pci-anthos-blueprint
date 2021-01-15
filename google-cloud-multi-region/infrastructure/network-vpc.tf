resource "google_compute_network" "multiregion" {
  name                    = "multiregion"
  project                 = google_project.network.project_id
  auto_create_subnetworks = false
  depends_on              = [google_project_service.services_app]
}

resource "google_compute_shared_vpc_host_project" "network" {
  project = google_project.network.project_id
}

resource "google_compute_shared_vpc_service_project" "app" {
  host_project    = google_project.network.project_id
  service_project = google_project.app.project_id
}
