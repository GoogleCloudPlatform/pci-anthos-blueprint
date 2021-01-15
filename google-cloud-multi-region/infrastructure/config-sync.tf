module "config_sync_r1_1" {
  source           = "github.com/terraform-google-modules/terraform-google-kubernetes-engine//modules/config-sync?ref=v12.3.0"
  project_id       = google_project.app.project_id
  cluster_name     = google_container_cluster.r1_1.name
  location         = google_container_cluster.r1_1.location
  cluster_endpoint = google_container_cluster.r1_1.endpoint
  sync_repo        = var.config_sync_sync_repo
  sync_branch      = var.config_sync_sync_branch
  policy_dir       = "${var.config_sync_sync_policy_dir_root}/r1-1"
  secret_type      = "ssh"
  ssh_auth_key     = local.config_sync_ssh_auth_key_path
}

module "config_sync_r1_2" {
  source           = "github.com/terraform-google-modules/terraform-google-kubernetes-engine//modules/config-sync?ref=v12.3.0"
  project_id       = google_project.app.project_id
  cluster_name     = google_container_cluster.r1_2.name
  location         = google_container_cluster.r1_2.location
  cluster_endpoint = google_container_cluster.r1_2.endpoint
  sync_repo        = var.config_sync_sync_repo
  sync_branch      = var.config_sync_sync_branch
  policy_dir       = "${var.config_sync_sync_policy_dir_root}/r1-2"
  secret_type      = "ssh"
  ssh_auth_key     = local.config_sync_ssh_auth_key_path
}

module "config_sync_r2_1" {
  source           = "github.com/terraform-google-modules/terraform-google-kubernetes-engine//modules/config-sync?ref=v12.3.0"
  project_id       = google_project.app.project_id
  cluster_name     = google_container_cluster.r2_1.name
  location         = google_container_cluster.r2_1.location
  cluster_endpoint = google_container_cluster.r2_1.endpoint
  sync_repo        = var.config_sync_sync_repo
  sync_branch      = var.config_sync_sync_branch
  policy_dir       = "${var.config_sync_sync_policy_dir_root}/r2-1"
  secret_type      = "ssh"
  ssh_auth_key     = local.config_sync_ssh_auth_key_path
}

module "config_sync_r2_2" {
  source           = "github.com/terraform-google-modules/terraform-google-kubernetes-engine//modules/config-sync?ref=v12.3.0"
  project_id       = google_project.app.project_id
  cluster_name     = google_container_cluster.r2_2.name
  location         = google_container_cluster.r2_2.location
  cluster_endpoint = google_container_cluster.r2_2.endpoint
  sync_repo        = var.config_sync_sync_repo
  sync_branch      = var.config_sync_sync_branch
  policy_dir       = "${var.config_sync_sync_policy_dir_root}/r2-2"
  secret_type      = "ssh"
  ssh_auth_key     = local.config_sync_ssh_auth_key_path
}

module "config_sync_r3_1" {
  source           = "github.com/terraform-google-modules/terraform-google-kubernetes-engine//modules/config-sync?ref=v12.3.0"
  project_id       = google_project.app.project_id
  cluster_name     = google_container_cluster.r3_1.name
  location         = google_container_cluster.r3_1.location
  cluster_endpoint = google_container_cluster.r3_1.endpoint
  sync_repo        = var.config_sync_sync_repo
  sync_branch      = var.config_sync_sync_branch
  policy_dir       = "${var.config_sync_sync_policy_dir_root}/r3-1"
  secret_type      = "ssh"
  ssh_auth_key     = local.config_sync_ssh_auth_key_path
}
