/* Create a dedicated IAM file for CF v2 build requirements

Why here:

Tied to environment
Easy to reason about
Easy to delete if Google fixes this someday
Avoids module-level circular dependencies */


locals {
  compute_default_sa = "${var.project_number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "cfv2_compute_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${local.compute_default_sa}"
}

resource "google_project_iam_member" "cfv2_compute_storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${local.compute_default_sa}"
}

resource "google_project_iam_member" "cfv2_compute_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${local.compute_default_sa}"
}

resource "google_project_iam_member" "cfv2_compute_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${local.compute_default_sa}"
}


locals {
  cloudbuild_service_account = "${var.project_number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "cloudbuild_builder" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${local.cloudbuild_service_account}"
}

resource "google_project_iam_member" "cloudbuild_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${local.cloudbuild_service_account}"
}


# -------------------------------------------------------------------
# Cloud Functions Gen 2 (Pub/Sub) requires unauthenticated invocation
# on the underlying Cloud Run service. This is intentional and safe.
# Do not remove unless changing the trigger model.
# -------------------------------------------------------------------

resource "google_cloud_run_service_iam_member" "billing_alerts_invoker" {
  service  = module.billing_alerts_function.cloud_run_service_name
  location = var.region
  project  = var.project_id

  role   = "roles/run.invoker"
  member = "serviceAccount:${module.iam.billing_alerts_service_account_email}"
}

