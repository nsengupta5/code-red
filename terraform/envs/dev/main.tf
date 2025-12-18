provider "google" {
  project = var.project_id
  region  = var.region
}

module "composer" {
  source = "../../modules/composer"
  name   = "dev-composer"
  region = var.region
}
