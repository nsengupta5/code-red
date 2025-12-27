variable "project_id" {
  type    = string
  default = "project-990b8649-da36-4d4c-9d9"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "composer_name" {
  type    = string
  default = "composer-dev"
}

variable "enable_composer" {
  description = "Whether to create the Cloud Composer environment"
  type        = bool
  default     = false
}

variable "airflow_ui_source_ranges" {
  type        = list(string)
  description = "CIDRs allowed to access Airflow UI and SSH"
}
