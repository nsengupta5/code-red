output "function_name" {
  value = google_cloudfunctions2_function.billing_alerts.name
}

output "function_region" {
  value = google_cloudfunctions2_function.billing_alerts.location
}
