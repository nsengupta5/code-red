resource "google_compute_firewall" "airflow_ui" {
  project = var.project_id
  name    = "${var.network_name}-allow-airflow-ui"
  network = google_compute_network.this.self_link

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges           = var.airflow_ui_source_ranges
  target_service_accounts = [var.airflow_service_account_email]

  direction = "INGRESS"
}


resource "google_compute_firewall" "ssh_ingress" {
  name    = "airflow-ssh"
  network = google_compute_network.this.self_link

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.airflow_ui_source_ranges

  target_tags = ["airflow-vm"]
}

