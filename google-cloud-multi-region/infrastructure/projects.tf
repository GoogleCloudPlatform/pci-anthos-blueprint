resource "google_project" "network" {
  name       = local.project-network
  project_id = local.project-network
  # folder_id           = var.infrastructure_folder_id
  billing_account     = var.billing_account
  auto_create_network = false
}
resource "google_project" "app" {
  name       = local.project-app
  project_id = local.project-app
  # folder_id           = var.infrastructure_folder_id
  billing_account     = var.billing_account
  auto_create_network = false
}

resource "google_project_service" "services_app" {
  project                    = google_project.app.project_id
  for_each                   = toset(var.application_services)
  service                    = each.key
  disable_dependent_services = true
  disable_on_destroy         = true
}

resource "google_project_service" "api_enabled_services_project_network" {
  project                    = google_project.network.project_id
  for_each                   = toset(var.api_enabled_services_project_network)
  service                    = each.key
  disable_dependent_services = true
  # this setting is causing trouble when true
  disable_on_destroy = false
}

output "app_project_raw_id" {
  value = trimprefix(google_project.app.id, "projects/")
}

output "network_project_raw_id" {
  value = trimprefix(google_project.network.id, "projects/")
}

