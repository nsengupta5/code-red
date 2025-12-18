provider "google" {
  project = var.project_id
  region  = var.region
}

module "composer" {
  source = "../../modules/composer"
  composer_name   = var.composer_name
  region = var.region
  project_id = var.project_id
}
