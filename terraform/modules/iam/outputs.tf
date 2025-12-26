output "composer_service_account_email" {
  description = "Composer runtime service account email"
  value       = google_service_account.composer.email
}

output "composer_sa_email" {
  description = "Service account email used by Cloud Composer"
  value = google_service_account.composer.email
}
