resource "null_resource" "init-meshconfig" {
  depends_on = [google_project_service.services_app, google_container_cluster.r3_1]
  # triggers = {
  #   always_run = uuid()
  # }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      APP_PROJECT_ID = google_project.app.project_id
    }
    command = "source ${local.project_root_path}/scripts/main.sh ; initialize_project_for_anthos"
  }
}