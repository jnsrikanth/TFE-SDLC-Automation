```markdown
# Terraform GCS Bucket Module

This module creates a simple Google Cloud Storage (GCS) bucket with essential configurations, focusing on simplicity, reusability, and best practices.

## Features

*   **Simple GCS Bucket Creation:** Easily provision a GCS bucket.
*   **Configurable:** Customize bucket name, location, and storage class.
*   **Enhanced Security:** Uniform bucket-level access is enabled by default, recommended for security.
*   **Label Support:** Apply custom labels for organization and filtering.
*   **Force Destroy Option:** Allows for bucket deletion even if it contains objects (use with extreme caution!).
*   **Project ID Flexibility:** Can utilize the provider's default project or a specified one.

## Design Principles

*   **Simplicity:** Prioritizes core bucket functionality. Complex configurations are intentionally omitted to keep the module focused and easy to understand.
*   **Reusability:** Designed to be easily incorporated into various Terraform projects.
*   **Best Practices:** Includes `uniform_bucket_level_access` by default for robust security.
*   **Limited Flexibility:** Offers common customization options without becoming overly complex.

## Module Structure

```
gcs-bucket/
├── main.tf         # Resource definitions
├── variables.tf    # Input variables
├── outputs.tf      # Output values
└── README.md       # Module documentation
```

## Usage

To use this module, include a `module` block in your Terraform configuration.

```terraform
# Example usage in your root Terraform configuration (e.g., main.tf)

provider "google" {
  project = "your-gcp-project-id"
  region  = "us-central1" # Or your preferred region
}

module "my_application_logs" {
  source = "./modules/gcs-bucket" # Adjust path if your module is located elsewhere

  bucket_name   = "my-unique-app-logs-bucket-12345" # Must be globally unique
  location      = "US-CENTRAL1"
  storage_class = "NEARLINE"
  project_id    = "your-gcp-project-id" # Optional: if not set in provider

  labels = {
    environment = "production"
    application = "my-application"
    purpose     = "logs"
  }
}

# Example outputting the bucket URL
output "application_logs_bucket_url" {
  description = "The URL of the application logs GCS bucket."
  value       = module.my_application_logs.url
}
```

### Source Options

The `source` argument in the `module` block can point to:

*   **Local Path:** `./modules/gcs-bucket` (as shown above)
*   **Terraform Registry:** `terraform-google-modules/gcs-bucket/google`
*   **Remote Git Repository:** `git::https://example.com/your-repo.git?ref=v1.0.0`

## Inputs

| Name                          | Description                                                                                             | Type          | Default     | Required |
| :---------------------------- | :------------------------------------------------------------------------------------------------------ | :------------ | :---------- | :------: |
| `bucket_name`                 | The globally unique name for the GCS bucket. Must be between 3 and 63 characters and follow naming conventions. | `string`      | n/a         |   yes    |
| `location`                    | The location where the bucket will be created. Examples: `US`, `EU`, `ASIA`, `US-CENTRAL1`.               | `string`      | `"US"`      |    no    |
| `storage_class`               | The storage class for the bucket. Examples: `STANDARD`, `NEARLINE`, `COLDLINE`, `ARCHIVE`.              | `string`      | `"STANDARD"`|    no    |
| `project_id`                  | The GCP project ID where the bucket will be created. If not provided, the provider's default project will be used. | `string`      | `null`      |    no    |
| `labels`                      | A map of labels to apply to the GCS bucket.                                                             | `map(string)` | `{}`        |    no    |
| `uniform_bucket_level_access` | Enables uniform bucket-level access. Recommended for security.                                          | `bool`        | `true`      |    no    |
| `force_destroy`               | Set to `true` to allow the bucket to be deleted even if it contains objects. Use with caution!          | `bool`        | `false`     |    no    |

## Outputs

| Name         | Description                                    |
| :----------- | :--------------------------------------------- |
| `id`         | The ID of the GCS bucket (e.g., `projects/_/buckets/your-bucket-name`). |
| `name`       | The globally unique name of the GCS bucket.    |
| `url`        | The URL to access the GCS bucket (e.g., `gs://your-bucket-name`). |
| `self_link`  | The self-link of the GCS bucket resource.      |

---

### How to Use This Module

1.  **Save the Files:** Create a directory (e.g., `modules/gcs-bucket`) and place the `main.tf`, `variables.tf`, `outputs.tf`, and this `README.md` file inside it.
2.  **Configure Provider:** Ensure your root Terraform configuration has a `provider "google"` block properly configured with your project and region.
3.  **Instantiate the Module:** Use the `module` block as demonstrated in the "Usage" section above, providing the necessary input variables.
4.  **Run Terraform:** Execute `terraform init`, `terraform plan`, and `terraform apply` in your root module's directory.

This module provides a solid foundation for creating GCS buckets. For more advanced configurations like lifecycle rules, versioning, or detailed IAM policies, consider extending this module or managing those aspects at a higher level in your infrastructure.
```