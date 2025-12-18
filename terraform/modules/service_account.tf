resource "google_service_account" "composer" {
  account_id   = "composer-env-sa"
  display_name = "Cloud Composer Environment Service Account"
}

resource "google_project_iam_member" "composer_worker" {
  role   = "roles/composer.worker"
  member = "serviceAccount:${google_service_account.composer.email}"
}

resource "google_project_iam_member" "composer_service_agent_ext" {
  role   = "roles/composer.ServiceAgentV2Ext"
  member = "serviceAccount:${google_service_account.composer.email}"
}
