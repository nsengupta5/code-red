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

####  (for templates + input)
resource "google_project_iam_member" "airflow_storage_object_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.airflow.email}"
}

#### (if writing temp/staging)
resource "google_project_iam_member" "airflow_storage_object_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.airflow.email}"
}

#### (if writing to BQ)
resource "google_project_iam_member" "airflow_bigquery_data_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.airflow.email}"
}

#### (Airflow VM launches Dataflow jobs that run under a different service account)
resource "google_project_iam_member" "airflow_iam_service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.airflow.email}"
}

#### Grant Airflow SA access to DAGs bucket ####
resource "google_storage_bucket_iam_member" "airflow_dag_reader" {
  bucket = var.airflow_dag_bucket_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.airflow.email}"
}

