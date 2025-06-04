#Public bucket
resource "google_storage_bucket" "storage_bucket" {
  name = "${var.bucket_name}-${random_id.name_suffix.hex}"
  location      = var.region
  storage_class = "STANDARD"

  lifecycle {
    prevent_destroy = false 
  }

  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true

}

#Private bucket
resource "google_storage_bucket" "private_bucket" {
  name          = "${var.priv_bucket}-${random_id.name_suffix.hex}"
  location      = var.region
  storage_class = "STANDARD"
  force_destroy = true

  public_access_prevention = "enforced"
}