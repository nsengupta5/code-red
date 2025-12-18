resource "google_composer_environment" "this" {
  name   = var.name
  region = var.region

  config {
    node_config {
      machine_type = "e2-small"
    }

    software_config {
      image_version = "composer-2-airflow-2"
    }

    environment_size = "ENVIRONMENT_SIZE_SMALL"
  }
}
