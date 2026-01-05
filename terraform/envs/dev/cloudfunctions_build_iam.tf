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
