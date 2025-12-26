data "google_project" "current" {
  project_id = var.project_id
}

locals {
  project_number = data.google_project.current.number

  # principalSet base for repo-scoped binding:
  # principalSet://iam.googleapis.com/projects/<POOL_PROJECT_NUMBER>/locations/global/workloadIdentityPools/<POOL_ID>/attribute.repository/<ORG>/<REPO>
  github_principal_set = "principalSet://iam.googleapis.com/projects/${var.wif_project_number}/locations/global/workloadIdentityPools/${var.wif_pool_id}/attribute.repository/${var.github_repo}"
}
