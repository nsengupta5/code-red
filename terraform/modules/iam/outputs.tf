output "airflow_service_account_email" {
  value = google_service_account.airflow.email
}

output "dags_deployer_service_account_email" {
  description = "Service account email for deploying dags"
  value       = google_service_account.dags_deployer.email
}



####  Commented out as Composer is too big to set up in a GCP Trail project ####

#output "composer_service_account_email" {
#  description = "Composer runtime service account email"
#  value       = google_service_account.composer.email
#}

#output "composer_sa_email" {
#  description = "Service account email used by Cloud Composer"
#  value = google_service_account.composer.email
#}

output "billing_alerts_service_account_email" {
  value = google_service_account.billing_alerts.email
}
