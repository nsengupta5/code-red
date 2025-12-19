output "composer_environment_name" {
  description = "Composer environment name (null if module is disabled)"
  value       = try(google_composer_environment.composer_instance.name, null)
}
