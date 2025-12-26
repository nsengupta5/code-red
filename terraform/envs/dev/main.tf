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
  count = var.enable_composer ? 1 : 0

  source                = "../../modules/composer"
  name                  = "dev-composer"
  region                = var.region
  service_account_email = module.iam.composer_service_account_email
}


module "iam" {
  source     = "../../modules/iam"
  project_id = var.project_id
}


module "stb_dummy" {
  source     = "../../modules/buckets"
  project_id = var.project_id
  name       = "dummy-data"
  location   = var.region
}

module "stb_dataflow-temp" {
  source     = "../../modules/buckets"
  project_id = var.project_id
  name       = "dataflow-temp"
  location   = var.region
}

module "stb_dataflow-staging" {
  source     = "../../modules/buckets"
  project_id = var.project_id
  name       = "dataflow-staging"
  location   = var.region
}


module "artifact_registry" {
  source = "../../modules/artifact_registry"

  project_id    = var.project_id
  location      = var.region
  repository_id = "buggy-python"
}


module "services" {
  source     = "../../modules/services"
  project_id = var.project_id

  services = [
    "run.googleapis.com",
    "dataflow.googleapis.com",
  ]
}
