data "terraform_remote_state" "admin" {
  backend = "gcs"
  config = {
    bucket = var.terraform_base_bucket_name
    prefix = var.terraform_base_bucket_prefix
  }
}

resource "google_cloudbuild_trigger" "builder" {
  name     = "build-production"
  provider = google-beta
  project  = data.terraform_remote_state.admin.outputs.admin_project_id
  filename = local.cloudbuild_yaml_filename
  github {
    owner = var.cloud_build_github_owner
    name  = var.cloud_build_repository_name
    push {
      branch = var.cloud_build_push_branch_pattern
    }
  }
  substitutions = {
    _PROJECT_PREFIX           = var.project_prefix
    _ORGANIZATION_ID          = var.organization_id
    _REGION                   = var.region
    _BILLING_ACCOUNT          = var.billing_account
    _FRONTEND_HOSTNAME        = var.frontend_hostname
    _FRONTEND_ZONE_DNS_NAME   = var.frontend_zone_dns_name
    _ACM_SYNCREPO             = var.acm_syncrepo
    _ACM_SYNCBRANCH           = var.acm_syncbranch
    _INFRASTRUCTURE_FOLDER_ID = data.terraform_remote_state.admin.outputs.infrastructure_folder_id
    _ADMIN_BUCKET             = data.terraform_remote_state.admin.outputs.admin-bucket-name
    _IN_SCOPE_CLUSTER         = var.in_scope_cluster
    _OUT_OF_SCOPE_CLUSTER     = var.out_of_scope_cluster
    _SRC_PATH                 = var.src_path
    _ASM_PATH                 = var.asm_path
  }
}

resource "google_secret_manager_secret_iam_binding" "cloud-build-service-account-access-to-deploy-key" {
  project   = data.terraform_remote_state.admin.outputs.admin_project_number
  secret_id = "projects/${data.terraform_remote_state.admin.outputs.admin_project_number}/secrets/config-management-deploy-key"
  role      = "roles/secretmanager.secretAccessor"
  members = [
    data.terraform_remote_state.admin.outputs.cloud-build-service-account
  ]
}

resource "google_cloudbuild_trigger" "terraform_destroy" {
  name     = "terraform-destroy"
  disabled = local.cloud_build_destroy_disabled
  provider = google-beta
  project  = data.terraform_remote_state.admin.outputs.admin_project_id
  filename = local.cloudbuild_yaml_destroy_filename
  github {
    owner = var.cloud_build_github_owner
    name  = var.cloud_build_repository_name
    push {
      tag = local.cloud_build_destroy_tag_regex_pattern
    }
  }
  substitutions = {
    _ADMIN_BUCKET             = data.terraform_remote_state.admin.outputs.admin-bucket-name
  }
}

