module "parent-folder" {
  source = "github.com/terraform-google-modules/terraform-google-folders?ref=00f2aac"
  parent = local.admin_parent
  names  = [local.admin_folder_name]
}

module "admin-project" {
  source                  = "github.com/terraform-google-modules/terraform-google-project-factory?ref=v9.1.0"
  random_project_id       = true
  name                    = local.admin_project_name
  folder_id               = module.parent-folder.id
  org_id                  = var.organization_id
  billing_account         = var.billing_account
  default_service_account = "keep"
  activate_apis           = local.admin_project_activate_apis
}

module "infrastructure-folder" {
  source = "github.com/terraform-google-modules/terraform-google-folders?ref=00f2aac"
  parent = module.parent-folder.id
  names  = [local.infrastructure_folder_name]
}
