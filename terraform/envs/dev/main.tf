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


#### Define Cloud Composer resource - note this is toggled on/off using dev.auto.tfvars ####

module "composer" {
  count = var.enable_composer ? 1 : 0

  source                = "../../modules/composer"
  name                  = "dev-composer"
  region                = var.region
  service_account_email = module.iam.composer_service_account_email
}


#### Service account creation and permissions ####

module "iam" {
  source = "../../modules/iam"

  project_id         = var.project_id
  github_repo        = "nsengupta5/code-red"
  wif_project_number = "258083003066"
  wif_pool_id        = "github-pool"
}


#### Define the GCS buckets ####

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


#### Define the artifact registry resource ####

module "artifact_registry" {
  source = "../../modules/artifact_registry"

  project_id    = var.project_id
  location      = var.region
  repository_id = "buggy-python"
}


#### Define the services to run in the project ####

module "services" {
  source     = "../../modules/services"
  project_id = var.project_id

  services = [
    "run.googleapis.com",
    "dataflow.googleapis.com",
    "compute.googleapis.com",
    "storage.googleapis.com",
    "artifactregistry.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
}


#### Define the BigQuery datasets in the project ####

module "bq_animal_facts" {
  source     = "../../modules/bigquery"
  project_id = var.project_id

  dataset_id = "animal_facts"
  location   = "US"

  # Safe for dev; set to false in prod
  delete_contents_on_destroy = true
}
