```hcl
# gcs-bucket/outputs.tf

output "bucket_name" {
  description = "The name of the created GCS bucket."
  value       = google_storage_bucket.this.name
}

output "bucket_url" {
  description = "The gsutil URI for the created GCS bucket."
  value       = google_storage_bucket.this.url
}

output "bucket_self_link" {
  description = "The self-link of the created GCS bucket."
  value       = google_storage_bucket.this.self_link
}
```