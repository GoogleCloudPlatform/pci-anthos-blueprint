# setting IAM policies

data "google_iam_policy" "this-policy" {
  binding {
    role = "roles/compute.networkUser"
    members = [
      "serviceAccount:${google_project.app.number}@cloudservices.gserviceaccount.com",
    ]
  }
  binding {
    role = "roles/compute.networkUser"
    members = [
      "serviceAccount:service-${google_project.app.number}@container-engine-robot.iam.gserviceaccount.com",
    ]
  }
}

resource "google_compute_subnetwork_iam_policy" "subnet-policy" {
  for_each    = var.subnetworks
  project     = google_project.network.project_id
  region      = each.value.region
  subnetwork  = each.value.name
  policy_data = data.google_iam_policy.this-policy.policy_data
  depends_on  = [google_compute_subnetwork.r1-1, google_compute_subnetwork.r1-2, google_compute_subnetwork.r2-1, google_compute_subnetwork.r2-2, google_compute_subnetwork.r3-1]
}

