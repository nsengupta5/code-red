output "function_name" {
  value = google_cloudfunctions2_function.billing_alerts.name
}

output "function_region" {
  value = google_cloudfunctions2_function.billing_alerts.location
}

output "cloud_run_service_name" {
  description = "Underlying Cloud Run service name for the billing alerts function"
  value       = google_cloudfunctions2_function.billing_alerts.name
}
