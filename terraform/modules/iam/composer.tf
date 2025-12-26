############################
# Composer runtime identity
############################

resource "google_service_account" "composer" {
  project      = var.project_id
  account_id   = "composer-env-sa"
  display_name = "Cloud Composer Runtime Service Account"
}

resource "google_project_iam_member" "composer_worker" {
  project = var.project_id
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.composer.email}"
}

############################
# Google-managed Composer service agent
############################
resource "google_project_iam_member" "composer_service_agent_ext" {
  project = var.project_id
  role    = "roles/composer.ServiceAgentV2Ext"
  member  = "serviceAccount:service-${local.project_number}@cloudcomposer-accounts.iam.gserviceaccount.com"
}
