# These outputs are consumed by the cloud-build/ root module
output "admin_project_id" {
  value = module.admin-project.project_id
}
output "admin_project_number" {
  value = module.admin-project.project_number
}
output "infrastructure_folder_id" {
  value = module.infrastructure-folder.id
}
output "cloud-build-service-account" {
  value = "serviceAccount:${module.admin-project.project_number}@cloudbuild.gserviceaccount.com"
}
output "admin-bucket-name" {
  value = module.admin-bucket.bucket.name
}