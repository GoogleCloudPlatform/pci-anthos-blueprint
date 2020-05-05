variable "project_prefix" {
  description = "Segment to prefix all project names with."
  default     = ""
}
variable "billing_account" {
  description = "The ID of the associated billing account"
  default     = ""
}
variable "organization_id" {
  description = "The Ggoogle Cloud Organization ID"
  default     = ""
}
variable "region" {
  description = "The Google Cloud region to use"
}

locals {
  admin_parent       = "organizations/${var.organization_id}"
  admin_folder_name  = "${var.project_prefix}-anthos"
  admin_project_name = "${var.project_prefix}-admin"
  admin_project_activate_apis = [
    "cloudbuild.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "secretmanager.googleapis.com",
    "iam.googleapis.com",
    "cloudbilling.googleapis.com",
    "container.googleapis.com",
    "serviceusage.googleapis.com"
  ]
  admin_bucket               = "admin"
  infrastructure_folder_name = "infrastructure"
  infrastructure_folder_roles = [
    "resourcemanager.projectCreator",
    "billing.projectManager",
    "compute.xpnAdmin",
    "compute.admin",
    "container.admin",
    "iam.serviceAccountKeyAdmin"
  ]
}
