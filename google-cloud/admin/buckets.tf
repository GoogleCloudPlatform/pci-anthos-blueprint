module "admin-bucket" {
  source     = "terraform-google-modules/cloud-storage/google"
  version    = "~> 1.7"
  project_id = module.admin-project.project_id
  names      = [local.admin_bucket]
  prefix     = var.project_prefix
   force_destroy = {
    (local.admin_bucket) = true
  }
  versioning = {
    (local.admin_bucket) = true
  }
}