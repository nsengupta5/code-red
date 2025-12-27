terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

locals {
  airflow_home = "/opt/airflow"
  venv_dir     = "/opt/airflow/venv"
  dags_dir     = "/opt/airflow/dags"

  constraints_url = "https://raw.githubusercontent.com/apache/airflow/constraints-${var.airflow_version}/constraints-${var.python_constraints_version}.txt"

  startup_script = templatefile("${path.module}/startup.sh.tftpl", {
    airflow_version            = var.airflow_version
    python_constraints_version = var.python_constraints_version
    constraints_url            = local.constraints_url
    airflow_home               = local.airflow_home
    venv_dir                   = local.venv_dir
    dags_dir                   = local.dags_dir
    airflow_executor           = var.airflow_executor
    airflow_webserver_port     = var.airflow_webserver_port
    airflow_admin_username     = var.airflow_admin_username
    airflow_admin_password     = var.airflow_admin_password
    airflow_admin_firstname    = var.airflow_admin_firstname
    airflow_admin_lastname     = var.airflow_admin_lastname
    airflow_admin_email        = var.airflow_admin_email
    install_providers_google   = var.install_providers_google
  })
}

resource "google_compute_instance" "this" {
  project      = var.project_id
  name         = var.name
  zone         = var.zone
  machine_type = var.machine_type
  tags         = var.network_tags

  boot_disk {
    initialize_params {
      image = var.boot_image
      size  = var.boot_disk_size_gb
      type  = var.boot_disk_type
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    dynamic "access_config" {
      for_each = var.assign_external_ip ? [1] : []
      content {}
    }
  }

  service_account {
    email  = var.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = merge(
    var.instance_metadata,
    {
      "startup-script" = local.startup_script
    }
  )

  labels = var.labels
}
