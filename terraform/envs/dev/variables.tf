variable "project_id" {
  type    = string
}

variable "project_number" {
  type        = string
  description = "GCP project number (required for billing budgets)"
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

variable "monthly_budget_amount" {
  description = "Monthly budget amount in GBP"
  type        = number
}

variable "billing_account_id" {
  type        = string
  description = "Billing account ID"
}

