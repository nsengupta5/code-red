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
#### Commented out as Composer is too big to set up in a GCP Trail project - Service accounts definitions set to disused in IAM modules (composer.tf.disused and outputs.tf.disused)
#module "composer" {
#  count = var.enable_composer ? 1 : 0
#
#  source                = "../../modules/composer"
#  name                  = "dev-composer"
#  region                = var.region
#  service_account_email = module.iam.composer_service_account_email
#}


#### Service account creation and permissions ####

module "iam" {
  source = "../../modules/iam"

  project_id         = var.project_id
  github_repo        = "nsengupta5/code-red"
  wif_project_number = "258083003066"
  wif_pool_id        = "github-pool"
  airflow_dag_bucket_name = module.stb_airflow-dags.bucket_name
  ci_service_account_email = "terraform-deployer@project-990b8649-da36-4d4c-9d9.iam.gserviceaccount.com"

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

module "stb_airflow-dags" {
  source     = "../../modules/buckets"
  project_id = var.project_id
  name       = "airflow-dags"
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
    "secretmanager.googleapis.com",
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


#### Define network resources #####

module "network" {
  source = "../../modules/network"

  project_id                    = var.project_id
  region                        = var.region
  network_name                  = "main-vpc"
  subnet_name                   = "main-subnet"
  subnet_cidr                   = "10.10.0.0/16"

  airflow_ui_source_ranges      = var.airflow_ui_source_ranges
  airflow_service_account_email = module.iam.airflow_service_account_email
}




#### Define Airflow VM resource ####

module "airflow_vm" {
  source = "../../modules/compute/airflow_vm"

  project_id = var.project_id
  name       = "airflow-dev"
  zone       = "us-central1-a"

  network    = module.network.vpc_self_link
  subnetwork = module.network.subnet_self_link

  service_account_email  = module.iam.airflow_service_account_email
  airflow_admin_password = local.airflow_admin_password

  network_tags = ["airflow-vm"]

  dag_gcs_bucket = module.stb_airflow-dags.bucket_name
}



