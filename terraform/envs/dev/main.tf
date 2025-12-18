provider "google" {
  project = var.project_id
  region  = var.region
}

module "composer" {
  source = "../../modules/composer"
  name   = var.composer_name
  region = var.region
}
