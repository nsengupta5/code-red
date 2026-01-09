output "repository_url" {
  description = "Base Docker repository URL"
  value       = "${var.location}-docker.pkg.dev/${var.project_id}/${var.repository_id}"
}

output "repository_id" {
  description = "The ID of the repository"
  value       = var.repository_id
}
