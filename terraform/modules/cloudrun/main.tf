resource "google_cloud_run_v2_job" "this" {
  name     = var.name
  location = var.location
  project  = var.project_id

  template {
    template {
      service_account = var.service_account_email
      containers {
        image = var.image
      }
    }
  }
}
