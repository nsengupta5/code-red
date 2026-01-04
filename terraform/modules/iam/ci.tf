############################
# CI identity (push images)
############################

resource "google_service_account" "ci_artifact_publisher" {
  project      = var.project_id
  account_id   = "ci-artifact-publisher"
  display_name = "CI Artifact Registry Publisher"
}

resource "google_project_iam_member" "ci_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.ci_artifact_publisher.email}"
}

############################
# GitHub Actions -> Workload Identity Federation binding
############################

resource "google_service_account_iam_member" "ci_wif_binding" {
  service_account_id = google_service_account.ci_artifact_publisher.name
  role               = "roles/iam.workloadIdentityUser"
  member             = local.github_principal_set
}


#### Grant CI SA access to DAGs bucket ####
resource "google_storage_bucket_iam_member" "ci_dag_writer" {
  bucket = var.airflow_dag_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.ci_service_account_email}"
}


############################
# GitHub Actions -> Grant CI Service Account access to Billing Account
############################


resource "google_billing_account_iam_member" "ci_billing_admin" {
  billing_account_id = var.billing_account_id
  role    = "roles/billing.admin"
  member  = "serviceAccount:${var.ci_service_account_email}"
}

############################
# GitHub Actions -> Grant CI Service Account access to Secret Manager (so that it can grant access to secrets)
############################

resource "google_project_iam_member" "ci_secret_manager_admin" {
  project = var.project_id
  role    = "roles/secretmanager.admin"
  member  = "serviceAccount:${var.ci_service_account_email}}"
}