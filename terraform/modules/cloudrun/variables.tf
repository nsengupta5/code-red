variable "name" {
  type        = string
  description = "The name of the Cloud Run job."
}

variable "project_id" {
  type        = string
  description = "The GCP project ID."
}

variable "location" {
  type        = string
  description = "The GCP region for the Cloud Run job."
}

variable "image" {
  type        = string
  description = "The container image to run."
}

variable "service_account_email" {
  type        = string
  description = "The service account email for the job to run as."
}
