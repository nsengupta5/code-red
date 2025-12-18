terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

module "composer" {
  source = "../../modules/composer"

  name                   = "dev-composer"
  region                 = var.region
  service_account_email  = module.iam.composer_service_account_email
}

module "iam" {
  source     = "../../modules/iam"
  project_id = var.project_id
}

