```markdown
# Terraform GCS Bucket Module

This module creates a simple Google Cloud Storage (GCS) bucket with common configurations. It's designed for reusability and ease of customization.

## Features

*   **Basic Bucket Creation:** Define bucket name, location, and storage class.
*   **Security Best Practices:** Enforces `uniform_bucket_level_access` by default.
*   **Versioning:** Optionally enable object versioning to protect against accidental overwrites or deletions.
*   **Static Website Hosting:** Configure the bucket to serve static website content.
*   **Labels:** Apply key-value labels for organization, filtering, and cost allocation.
*   **Force Destroy:** Option to enable `force_destroy` for easier cleanup during development or testing. **Use with extreme caution in production environments.**

## Prerequisites

*   Google Cloud Platform (GCP) account with appropriate permissions.
*   Terraform installed.
*   Google Cloud provider configured for Terraform.

## Usage

To use this module, include it in your Terraform configuration as shown below. You can specify the `source` as a local path or a Git repository.

```terraform
module "my_app_bucket" {
  source = "./modules/gcs-bucket" # Or a Git repository URL like "git::https://github.com/your-username/your-repo.git?ref=v1.0.0"

  bucket_name = "my-unique-app-data-bucket-12345" # Replace with your globally unique bucket name
  location    = "US-EAST1"
  storage_class = "STANDARD"

  labels = {
    environment = "production"
    app         = "my-app"
  }

  # Optional: Enable versioning
  # versioning = {
  #   enabled = true
  # }

  # Optional: Configure for static website hosting
  # website = {
  #   main_page_suffix = "index.html"
  #   not_found_page   = "404.html"
  # }

  # Optional: Enable force destroy (use with caution!)
  # force_destroy = true
}
```

### Example with Static Website Hosting and Versioning

```terraform
module "static_website_bucket" {
  source = "./modules/gcs-bucket"

  bucket_name = "my-unique-static-site-assets-54321"
  location    = "EUROPE-WEST2"
  storage_class = "NEARLINE"

  uniform_bucket_level_access = false # Example of overriding default

  versioning = {
    enabled = true
  }

  website = {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  labels = {
    purpose = "website-assets"
  }
}
```

## Inputs

| Name                               | Description                                                                                              | Type                                                                                                      | Default                                  | Required |
| :--------------------------------- | :------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------- | :--------------------------------------- | :------: |
| `bucket_name`                      | The globally unique name for the GCS bucket.                                                             | `string`                                                                                                  | -                                        |   yes    |
| `location`                         | The location for the GCS bucket. See [Google Cloud Storage Locations](https://cloud.google.com/storage/docs/locations). | `string`                                                                                                  | `"US-CENTRAL1"`                          |    no    |
| `storage_class`                    | The storage class for the GCS bucket. (e.g., `STANDARD`, `NEARLINE`, `COLDLINE`, `ARCHIVE`).             | `string`                                                                                                  | `"STANDARD"`                             |    no    |
| `uniform_bucket_level_access`      | Enables uniform bucket-level access. Recommended for security.                                           | `bool`                                                                                                    | `true`                                   |    no    |
| `force_destroy`                    | If true, Terraform will allow the bucket to be destroyed even if it contains objects. Use with caution.    | `bool`                                                                                                    | `false`                                  |    no    |
| `versioning`                       | Configuration for object versioning.                                                                     | `object({ enabled = bool })`                                                                              | `{ enabled = false }`                    |    no    |
| `labels`                           | A map of labels to assign to the bucket.                                                                 | `map(string)`                                                                                             | `{}`                                     |    no    |
| `website`                          | Optional website configuration for the bucket.                                                           | `object({ main_page_suffix = string, not_found_page = string })`                                        | `null`                                   |    no    |

## Outputs

| Name              | Description                              |
| :---------------- | :--------------------------------------- |
| `bucket_name`     | The name of the created GCS bucket.      |
| `bucket_url`      | The gsutil URI for the created GCS bucket. |
| `bucket_self_link`| The self-link of the created GCS bucket. |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an issue.

## License

This project is licensed under the MIT License.
```