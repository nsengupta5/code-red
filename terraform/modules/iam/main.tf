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
