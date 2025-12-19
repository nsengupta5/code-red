data "google_project" "current" {
  project_id = var.project_id
}

locals {
  project_number = data.google_project.current.number
}
