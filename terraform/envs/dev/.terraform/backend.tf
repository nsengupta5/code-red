terraform {
  backend "gcs" {
    bucket = "project-990b8649-da36-4d4c-9d9-tf-state"
    prefix = "dev"
  }
}
