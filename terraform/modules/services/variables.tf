variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "services" {
  description = "List of APIs to enable"
  type        = set(string)
}