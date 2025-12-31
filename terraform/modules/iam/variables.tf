variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository in the form <org>/<repo>"
  type        = string
}

variable "wif_project_number" {
  description = "Project number that owns the Workload Identity Pool (often same as this project)"
  type        = string
}

variable "wif_pool_id" {
  description = "Workload Identity Pool ID"
  type        = string
  default     = "github-pool"
}

variable "airflow_dag_bucket_name" {
  type        = string
  description = "GCS bucket name that stores Airflow DAGs"
}

variable "ci_service_account_email" {
  type        = string
  description = "Service account used by CI/CD (GitHub Actions)"
}
