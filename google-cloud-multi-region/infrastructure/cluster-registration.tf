module "register-r1_1" {
  source                  = "github.com/terraform-google-modules/terraform-google-kubernetes-engine//modules/hub?ref=v12.3.0"
  project_id              = google_container_cluster.r1_1.project
  cluster_name            = google_container_cluster.r1_1.name
  cluster_endpoint        = google_container_cluster.r1_1.endpoint
  gke_hub_membership_name = replace(google_container_cluster.r1_1.name, "_", "-") # must be dns spec RFC 1123
  # depends_on is causing a count related error. However, hub registration is dependent on node existence. This forces the dependency:
  location = google_container_node_pool.r1_1.location
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account#account_id
  gke_hub_sa_name = format("%s%s", replace(google_container_cluster.r1_1.name, "_", "-"), "-service-account")
}

module "register-r1_2" {
  source                  = "github.com/terraform-google-modules/terraform-google-kubernetes-engine//modules/hub?ref=v12.3.0"
  project_id              = google_container_cluster.r1_2.project
  cluster_name            = google_container_cluster.r1_2.name
  cluster_endpoint        = google_container_cluster.r1_2.endpoint
  gke_hub_membership_name = replace(google_container_cluster.r1_2.name, "_", "-") # must be dns spec RFC 1123
  location                = google_container_node_pool.r1_2.location
  gke_hub_sa_name         = format("%s%s", replace(google_container_cluster.r1_2.name, "_", "-"), "-service-account")
}

module "register-r2_1" {
  source                  = "github.com/terraform-google-modules/terraform-google-kubernetes-engine//modules/hub?ref=v12.3.0"
  project_id              = google_container_cluster.r2_1.project
  cluster_name            = google_container_cluster.r2_1.name
  cluster_endpoint        = google_container_cluster.r2_1.endpoint
  gke_hub_membership_name = replace(google_container_cluster.r2_1.name, "_", "-") # must be dns spec RFC 1123
  location                = google_container_node_pool.r2_1.location
  gke_hub_sa_name         = format("%s%s", replace(google_container_cluster.r2_1.name, "_", "-"), "-service-account")
}

module "register-r2_2" {
  source                  = "github.com/terraform-google-modules/terraform-google-kubernetes-engine//modules/hub?ref=v12.3.0"
  project_id              = google_container_cluster.r2_2.project
  cluster_name            = google_container_cluster.r2_2.name
  cluster_endpoint        = google_container_cluster.r2_2.endpoint
  gke_hub_membership_name = replace(google_container_cluster.r2_2.name, "_", "-") # must be dns spec RFC 1123
  location                = google_container_node_pool.r2_2.location
  gke_hub_sa_name         = format("%s%s", replace(google_container_cluster.r2_2.name, "_", "-"), "-service-account")
}

module "register-r3_1" {
  source                  = "github.com/terraform-google-modules/terraform-google-kubernetes-engine//modules/hub?ref=v12.3.0"
  project_id              = google_container_cluster.r3_1.project
  cluster_name            = google_container_cluster.r3_1.name
  cluster_endpoint        = google_container_cluster.r3_1.endpoint
  gke_hub_membership_name = replace(google_container_cluster.r3_1.name, "_", "-") # must be dns spec RFC 1123
  location                = google_container_node_pool.r3_1.location
  gke_hub_sa_name         = format("%s%s", replace(google_container_cluster.r3_1.name, "_", "-"), "-service-account")
}
