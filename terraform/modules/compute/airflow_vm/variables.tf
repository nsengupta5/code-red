variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "zone" {
  type = string
}

variable "machine_type" {
  type    = string
  default = "e2-small"
}

variable "network" {
  type = string
}

variable "subnetwork" {
  type    = string
  default = null
}

variable "assign_external_ip" {
  type    = bool
  default = true
}

variable "network_tags" {
  type    = list(string)
  default = []
}

variable "service_account_email" {
  type        = string
  description = "Pre-created service account email (from IAM module)"
}

variable "boot_image" {
  type    = string
  default = "projects/debian-cloud/global/images/family/debian-12"
}

variable "boot_disk_size_gb" {
  type    = number
  default = 30
}

variable "boot_disk_type" {
  type    = string
  default = "pd-balanced"
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "instance_metadata" {
  type    = map(string)
  default = {}
}

# Airflow config
variable "airflow_version" {
  type    = string
  default = "2.8.1"
}

variable "python_constraints_version" {
  type    = string
  default = "3.11"
}

variable "airflow_executor" {
  type        = string
  description = "Airflow executor to use"

  validation {
    condition = (
      var.airflow_executor == "SequentialExecutor" ||
      var.airflow_executor != "LocalExecutor"
    )
    error_message = "LocalExecutor cannot be used with SQLite. Use SequentialExecutor or configure Postgres/MySQL."
  }
}


variable "airflow_webserver_port" {
  type    = number
  default = 8080
}

variable "airflow_admin_username" {
  type    = string
  default = "admin"
}

variable "airflow_admin_password" {
  type      = string
  sensitive = true
}

variable "airflow_admin_firstname" {
  type    = string
  default = "Admin"
}

variable "airflow_admin_lastname" {
  type    = string
  default = "User"
}

variable "airflow_admin_email" {
  type    = string
  default = "admin@example.com"
}

variable "install_providers_google" {
  type    = bool
  default = true
}

variable "dag_gcs_bucket" {
  type        = string
  description = "GCS bucket containing Airflow DAGs"
}

variable "sync_script" {
  type        = string
  description = "Bash script used to sync Airflow DAGs from GCS"
}
