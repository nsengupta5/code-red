# Get project number (needed for Composer service agent)
data "google_project" "current" {
  project_id = var.project_id
}

# Composer runtime service account (used by Airflow workloads)
resource "google_service_account" "composer" {
  project      = var.project_id
  account_id   = "composer-env-sa"
  display_name = "Cloud Composer Runtime Service Account"
}

# Permissions for Airflow workers
resource "google_project_iam_member" "composer_worker" {
  project = var.project_id
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.composer.email}"
}

# REQUIRED: permissions for the Google-managed Composer service agent
resource "google_project_iam_member" "composer_service_agent_ext" {
  project = var.project_id
  role    = "roles/composer.ServiceAgentV2Ext"
  member  = "serviceAccount:service-${data.google_project.current.number}@cloudcomposer-accounts.iam.gserviceaccount.com"
}

# CI image publisher service account
resource "google_service_account" "ci_artifact_publisher" {
  account_id   = "ci-artifact-publisher"
  display_name = "CI Artifact Registry Publisher"
}

resource "google_project_iam_member" "ci_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.ci_artifact_publisher.email}"
}

resource "google_service_account_iam_member" "ci_wif_binding" {
  service_account_id = google_service_account.ci_artifact_publisher.name
  role               = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/projects/258083003066/locations/global/workloadIdentityPools/github-pool/attribute.repository/nsengupta5/code-red"
}
