# This is where bucket resources are defined



# Dummy data bucket 
resource "google_storage_bucket" "dummyData" {
  name          = "stb-raw-${local.project_number}"
  location      = var.location
  storage_class = "STANDARD"

  uniform_bucket_level_access = true


}
