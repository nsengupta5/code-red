output "vpc_name" {
  value = google_compute_network.this.name
}

output "vpc_self_link" {
  value = google_compute_network.this.self_link
}

output "subnet_name" {
  value = google_compute_subnetwork.this.name
}

output "subnet_self_link" {
  value = google_compute_subnetwork.this.self_link
}

output "subnet_region" {
  value = google_compute_subnetwork.this.region
}
