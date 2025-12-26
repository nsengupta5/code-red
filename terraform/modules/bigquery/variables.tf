variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "dataset_id" {
  type        = string
  description = "BigQuery dataset ID"
}

variable "location" {
  type        = string
  description = "Dataset location (e.g. US, EU)"
  default     = "US"
}

variable "delete_contents_on_destroy" {
  type        = bool
  description = "Whether to delete tables on destroy (dev only)"
  default     = true
}
