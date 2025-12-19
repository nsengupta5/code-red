variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "location" {
  description = "Artifact Registry location (e.g. us-central1)"
  type        = string
}

variable "repository_id" {
  description = "Artifact Registry repository name"
  type        = string
}
