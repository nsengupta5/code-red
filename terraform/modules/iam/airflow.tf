# modules/iam/airflow.tf

resource "google_service_account" "airflow" {
  account_id   = "airflow-vm"
  display_name = "Airflow VM Service Account"
}

resource "google_project_iam_member" "airflow_dataflow" {
  project = var.project_id
  role    = "roles/dataflow.developer"
  member  = "serviceAccount:${google_service_account.airflow.email}"
}
