data "google_secret_manager_secret_version" "airflow_admin_password" {
  project = var.project_id
  secret  = "airflow-admin-password"
  version = "latest"
}

locals {
  airflow_admin_password = data.google_secret_manager_secret_version.airflow_admin_password.secret_data
}
