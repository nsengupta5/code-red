resource "google_composer_environment" "composer_instance" {
  provider = google-beta

  name   = var.name
  region = var.region

  config {
    environment_size = "ENVIRONMENT_SIZE_SMALL"

    node_config {
      service_account = var.service_account_email
    }

    software_config {
      image_version = var.image_version
    }

    workloads_config {
      scheduler {
        cpu        = 1
        memory_gb = 3.75
        storage_gb = 5
        count      = 1
      }

      web_server {
        cpu        = 1
        memory_gb = 3.75
        storage_gb = 5
      }

      worker {
        cpu        = 1
        memory_gb = 3.75
        storage_gb = 5
        min_count  = 1
        max_count  = 1
      }
    }

  }
}
