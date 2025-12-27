variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "network_name" {
  type        = string
  description = "VPC network name"
  default     = "main-vpc"
}

variable "subnet_name" {
  type        = string
  description = "Subnetwork name"
  default     = "main-subnet"
}

variable "region" {
  type        = string
  description = "Region for the subnetwork"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR range for the subnetwork"
  default     = "10.10.0.0/16"
}

# Airflow-specific (optional but already in use)
variable "airflow_service_account_email" {
  type        = string
  description = "Service account email for Airflow VM"
}

variable "airflow_ui_source_ranges" {
  type        = list(string)
  description = "CIDRs allowed to access Airflow UI"
  default     = []
}
