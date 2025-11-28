```terraform
# gcs-bucket/main.tf

resource "google_storage_bucket" "this" {
  name          = var.bucket_name
  location      = var.location
  storage_class = var.storage_class

  # Optional configurations - controlled by variables
  uniform_bucket_level_access = var.uniform_bucket_level_access
  force_destroy               = var.force_destroy
  versioning                  = var.versioning
  labels                      = var.labels

  # Add more common configurations as needed, e.g., lifecycle rules, CORS, etc.
  # For a simple module, we'll keep it focused initially.

  dynamic "website" {
    for_each = var.website == null ? [] : [var.website]
    content {
      main_page_suffix = website.value.main_page_suffix
      not_found_page   = website.value.not_found_page
    }
  }
}
```