data "google_project" "current" {
  project_id = var.project_id
}

locals {
  project_number = data.google_project.current.number
  bucket_name    = "${var.name}-${local.project_number}"
}

resource "google_storage_bucket" "this" {
  name          = local.bucket_name
  location      = var.location
  storage_class = var.storage_class
  force_destroy = var.force_destroy

  uniform_bucket_level_access = true

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      condition {
        age = lifecycle_rule.value.age
      }
      action {
        type = lifecycle_rule.value.action
      }
    }
  }
}