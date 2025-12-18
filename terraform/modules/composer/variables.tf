variable "name" { type = string }
variable "region" { type = string }
variable "image_version" {
  type    = string
  default = "composer-2-airflow-2"
}
