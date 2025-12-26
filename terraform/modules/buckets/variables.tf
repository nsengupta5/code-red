variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "name" {
  description = "Bucket name prefix (project number will be appended)"
  type        = string
}

variable "location" {
  description = "Bucket location"
  type        = string
}

variable "storage_class" {
  description = "GCS storage class"
  type        = string
  default     = "STANDARD"
}

variable "force_destroy" {
  description = "Allow bucket deletion with objects"
  type        = bool
  default     = false
}

variable "lifecycle_rules" {
  description = "Optional lifecycle rules"
  type = list(object({
    age    = number
    action = string
  }))
  default = []
}
