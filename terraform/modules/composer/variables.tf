variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "service_account_email" {
  type        = string
  description = "Service account used by the Composer environment"
}

variable "image_version" {
  type    = string
  default = "composer-2-airflow-2"
}
