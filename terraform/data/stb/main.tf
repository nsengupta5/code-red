# This is where bucket resources are defined



# Dummy data bucket 
resource "google_storage_bucket" "dummyData" {
  name          = "dummy-data-${local.project_number}"
  location      = var.location
  storage_class = "STANDARD"

  uniform_bucket_level_access = true


}
