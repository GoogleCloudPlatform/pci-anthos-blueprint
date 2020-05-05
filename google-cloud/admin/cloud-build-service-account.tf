# Add a list of roles to the cloud build service account in the admin project
resource "google_folder_iam_binding" "infrastructure-folder" {
  folder   = module.infrastructure-folder.id
  for_each = toset(local.infrastructure_folder_roles)
  role     = "roles/${each.key}"
  members = [
    "serviceAccount:${module.admin-project.project_number}@cloudbuild.gserviceaccount.com",
  ]
}

# Set billing.user for the service account on the billing account
resource "google_billing_account_iam_binding" "binding" {
  billing_account_id = var.billing_account
  role               = "roles/billing.user"
  members = [
    "serviceAccount:${module.admin-project.project_number}@cloudbuild.gserviceaccount.com",
  ]
}

