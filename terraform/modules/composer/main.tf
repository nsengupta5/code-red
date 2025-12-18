resource "google_composer_environment" "composer_instance" {
  provider = google-beta

  name   = var.name
  region = var.region

  config {
    environment_size = "ENVIRONMENT_SIZE_SMALL"

    node_config {
      service_account = google_service_account.composer.email
    }

    software_config {
      image_version = var.image_version
    }

    workloads_config {
      scheduler {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        count      = 1
      }

      web_server {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
      }

      worker {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        min_count  = 1
        max_count  = 1
      }
    }
  }
}
