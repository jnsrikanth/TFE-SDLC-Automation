Okay, Architect! Let's design a simple and robust Terraform module for creating a Google Cloud Storage (GCS) bucket.

Here's a breakdown of the module's structure, its Terraform code, and explanations.

## GCS Bucket Module Design

**Goal:** To provide a reusable Terraform module that creates a basic GCS bucket with essential configurations.

**Key Considerations:**

*   **Simplicity:** Focus on core bucket creation. Avoid overly complex configurations that might be better handled at the environment or project level.
*   **Reusability:** Allow for easy customization of bucket name, location, and storage class.
*   **Best Practices:** Include essential attributes like `uniform_bucket_level_access` for security.
*   **Flexibility (Limited):** While simple, offer some common options.

---

### Module Structure

A standard Terraform module structure is ideal.

```
gcs-bucket/
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

---

### `variables.tf` - Input Variables

These are the parameters users can provide when using the module.

```terraform
# gcs-bucket/variables.tf

variable "bucket_name" {
  description = "The globally unique name for the GCS bucket."
  type        = string
  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters long."
  }
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._-]{0,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must contain only lowercase letters, numbers, dots, underscores, and hyphens. It must start and end with a letter or number."
  }
}

variable "location" {
  description = "The location where the bucket will be created. Examples: US, EU, ASIA, US-CENTRAL1."
  type        = string
  default     = "US" # Sensible default
}

variable "storage_class" {
  description = "The storage class for the bucket. Examples: STANDARD, NEARLINE, COLDLINE, ARCHIVE."
  type        = string
  default     = "STANDARD" # Sensible default
  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "Invalid storage class. Must be one of: STANDARD, NEARLINE, COLDLINE, ARCHIVE."
  }
}

variable "project_id" {
  description = "The GCP project ID where the bucket will be created. If not provided, the provider's default project will be used."
  type        = string
  default     = null # Allow provider to define
}

variable "labels" {
  description = "A map of labels to apply to the GCS bucket."
  type        = map(string)
  default     = {}
}

variable "uniform_bucket_level_access" {
  description = "Enables uniform bucket-level access. Recommended for security."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Set to true to allow the bucket to be deleted even if it contains objects. Use with caution!"
  type        = bool
  default     = false
}
```

---

### `main.tf` - Resource Definition

This is where the GCS bucket resource is defined.

```terraform
# gcs-bucket/main.tf

resource "google_storage_bucket" "this" {
  # If project_id is provided, use it. Otherwise, rely on the provider's default.
  project = var.project_id != null ? var.project_id : null

  name                        = var.bucket_name
  location                    = var.location
  storage_class               = var.storage_class
  uniform_bucket_level_access = var.uniform_bucket_level_access
  force_destroy               = var.force_destroy

  labels = var.labels

  # Optional: Lifecycle rules can be added here if needed, but for a "simple"
  # module, we'll keep it out of scope for now to maintain simplicity.
  # lifecycle_rule { ... }

  # Optional: Versioning can be enabled here.
  # versioning {
  #   enabled = true
  # }
}
```

---

### `outputs.tf` - Output Values

These are the values that can be exported from the module for use elsewhere.

```terraform
# gcs-bucket/outputs.tf

output "id" {
  description = "The ID of the GCS bucket."
  value       = google_storage_bucket.this.id
}

output "name" {
  description = "The name of the GCS bucket."
  value       = google_storage_bucket.this.name
}

output "url" {
  description = "The URL of the GCS bucket."
  value       = google_storage_bucket.this.url
}

output "self_link" {
  description = "The self_link of the GCS bucket."
  value       = google_storage_bucket.this.self_link
}
```

---

### `README.md` - Documentation

This is crucial for making your module usable.

```markdown
# Terraform GCS Bucket Module

This module creates a simple Google Cloud Storage (GCS) bucket.

## Features

*   Creates a GCS bucket.
*   Configurable bucket name, location, and storage class.
*   Enforces uniform bucket-level access by default for enhanced security.
*   Supports custom labels.
*   Option to force destroy (use with extreme caution).

## Usage

```terraform
module "my_data_bucket" {
  source = "./modules/gcs-bucket" # Or a Git repository, Terraform Registry

  bucket_name   = "my-unique-app-data-bucket-12345"
  location      = "US-CENTRAL1"
  storage_class = "NEARLINE"
  project_id    = "your-gcp-project-id" # Optional, if not set in provider

  labels = {
    environment = "production"
    application = "my-app"
  }
}
```

## Inputs

| Name                          | Description                                                                                             | Type          | Default     | Required |
| :---------------------------- | :------------------------------------------------------------------------------------------------------ | :------------ | :---------- | :------: |
| `bucket_name`                 | The globally unique name for the GCS bucket.                                                            | `string`      | n/a         |   yes    |
| `location`                    | The location where the bucket will be created. Examples: US, EU, ASIA, US-CENTRAL1.                     | `string`      | `"US"`      |    no    |
| `storage_class`               | The storage class for the bucket. Examples: STANDARD, NEARLINE, COLDLINE, ARCHIVE.                      | `string`      | `"STANDARD"`|    no    |
| `project_id`                  | The GCP project ID where the bucket will be created. If not provided, the provider's default project will be used. | `string`      | `null`      |    no    |
| `labels`                      | A map of labels to apply to the GCS bucket.                                                             | `map(string)` | `{}`        |    no    |
| `uniform_bucket_level_access` | Enables uniform bucket-level access. Recommended for security.                                          | `bool`        | `true`      |    no    |
| `force_destroy`               | Set to `true` to allow the bucket to be deleted even if it contains objects. Use with caution!          | `bool`        | `false`     |    no    |

## Outputs

| Name         | Description               |
| :----------- | :------------------------ |
| `id`         | The ID of the GCS bucket. |
| `name`       | The name of the GCS bucket.|
| `url`        | The URL of the GCS bucket.|
| `self_link`  | The self_link of the GCS bucket.|
```

---

### How to Use the Module

1.  **Save the files:** Create a directory (e.g., `modules/gcs-bucket`) and place the `main.tf`, `variables.tf`, `outputs.tf`, and `README.md` files inside it.
2.  **In your main Terraform configuration:**
    *   Ensure you have a `provider "google"` block configured.
    *   Use the `module` block as shown in the `README.md` example.

```terraform
# main.tf (in your root module)

provider "google" {
  project = "your-gcp-project-id"
  region  = "us