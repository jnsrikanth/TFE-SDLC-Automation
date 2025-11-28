Okay, Architect! Let's craft that README.md for your `gcs_bucket` Terraform module.

---

```markdown
# Terraform Module: `gcs_bucket`

This Terraform module provides a simple and reusable way to create Google Cloud Storage (GCS) buckets. It focuses on the essential configurations, making it easy to integrate into your infrastructure deployments across various projects and environments.

## Purpose

The primary goal of this module is to abstract the common configurations for Google Cloud Storage buckets, promoting consistency and reducing boilerplate code in your Terraform configurations.

## Key Features

*   **Simple and Focused:** Primarily handles the creation of GCS buckets with essential configurations.
*   **Configurable Name:** Allows specifying a unique name for the GCS bucket.
*   **Location Specification:** Supports defining the geographic location of the bucket.
*   **Storage Class Selection:** Enables choosing the appropriate storage class (e.g., `STANDARD`, `NEARLINE`, `COLDLINE`, `ARCHIVE`).
*   **Object Versioning:** Optionally enables object versioning for data protection and recovery.
*   **Uniform Bucket-Level Access:** Enforces uniform access control, simplifying IAM management.
*   **Labels:** Allows assigning custom labels for organization and cost allocation.
*   **Project Specification:** Optionally allows specifying the GCP project ID to deploy the bucket into.

## Module Structure

The module is organized as follows:

```
modules/
└── gcs_bucket/
    ├── main.tf       # Core resource definition
    ├── variables.tf  # Input variable definitions
    └── outputs.tf    # Output value definitions
```

## Files

### `modules/gcs_bucket/variables.tf`

This file defines the input variables that can be used to customize the GCS bucket creation.

```terraform
# modules/gcs_bucket/variables.tf

variable "bucket_name" {
  description = "The name of the GCS bucket. Must be globally unique and adhere to GCS naming conventions (3-63 characters, lowercase letters, numbers, dashes, underscores)."
  type        = string
  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63 && !can(regex("[^a-z0-9_-]", var.bucket_name))
    error_message = "Bucket names must be between 3 and 63 characters long and can only contain lowercase letters, numbers, dashes (-), and underscores (_)."
  }
}

variable "location" {
  description = "The location of the GCS bucket. Examples: US, EU, ASIA, US-CENTRAL1, EUROPE-WEST1."
  type        = string
  default     = "US" # Sensible default for broad availability
}

variable "storage_class" {
  description = "The storage class of the GCS bucket. Examples: STANDARD, NEARLINE, COLDLINE, ARCHIVE."
  type        = string
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "Invalid storage class. Must be one of: STANDARD, NEARLINE, COLDLINE, ARCHIVE."
  }
}

variable "enable_versioning" {
  description = "Whether to enable object versioning for the bucket. Recommended for data protection."
  type        = bool
  default     = false
}

variable "uniform_bucket_level_access" {
  description = "Enables uniform bucket-level access. This is the recommended setting for simplified and consistent access control."
  type        = bool
  default     = true
}

variable "labels" {
  description = "A map of labels to assign to the bucket for organization and billing."
  type        = map(string)
  default     = {}
}

variable "project_id" {
  description = "The GCP project ID to deploy the bucket into. If not provided, the default project from the Google provider configuration will be used."
  type        = string
  default     = null
}
```

### `modules/gcs_bucket/main.tf`

This file contains the core Terraform resource definition for creating the Google Cloud Storage bucket.

```terraform
# modules/gcs_bucket/main.tf

resource "google_storage_bucket" "this" {
  name                        = var.bucket_name
  location                    = var.location
  storage_class               = var.storage_class
  uniform_bucket_level_access = var.uniform_bucket_level_access
  labels                      = var.labels

  # Conditionally set the project if it's explicitly provided.
  # Otherwise, it will inherit the project from the Google provider's configuration.
  project = var.project_id != null ? var.project_id : null

  versioning {
    enabled = var.enable_versioning
  }

  # --- Optional configurations (commented out by default) ---
  # You can uncomment and configure these as needed:

  # Lifecycle rules for automatic object management
  # lifecycle_rule {
  #   condition {
  #     age = 30 # Delete objects older than 30 days
  #   }
  #   action {
  #     type = "Delete"
  #   }
  # }

  # CORS configuration for web applications
  # cors {
  #   origin = ["http://example.com"]
  #   method = ["GET", "HEAD", "PUT"]
  #   response_header = ["Content-Type"]
  #   max_age_seconds = 3600
  # }
}
```

### `modules/gcs_bucket/outputs.tf`

This file defines the output values that the module will expose after creation.

```terraform
# modules/gcs_bucket/outputs.tf

output "bucket_id" {
  description = "The unique ID of the GCS bucket (e.g., projects/_/buckets/my-bucket-name)."
  value       = google_storage_bucket.this.id
}

output "bucket_name" {
  description = "The name of the GCS bucket."
  value       = google_storage_bucket.this.name
}

output "bucket_url" {
  description = "The URL of the GCS bucket (e.g., gs://my-bucket-name)."
  value       = google_storage_bucket.this.url
}

output "location" {
  description = "The location where the GCS bucket is stored."
  value       = google_storage_bucket.this.location
}

output "storage_class" {
  description = "The storage class assigned to the GCS bucket."
  value       = google_storage_bucket.this.storage_class
}

output "versioning_enabled" {
  description = "Indicates whether object versioning is enabled for the GCS bucket."
  value       = google_storage_bucket.this.versioning[0].enabled
}
```

## How to Use This Module

1.  **Create the Module Directory:**
    Ensure you have a directory structure like this for your module:
    ```bash
    mkdir -p ./modules/gcs_bucket
    ```

2.  **Place Module Files:**
    Save the `main.tf`, `variables.tf`, and `outputs.tf` files into the `./modules/gcs_bucket/` directory.

3.  **Reference the Module in Your Root Configuration:**
    In your main Terraform configuration file (e.g., `main.tf` in your root directory), you can use the module as follows:

    ```terraform
    # main.tf (in your root directory)

    # Configure the Google Cloud provider
    provider "google" {
      project = "your-gcp-project-id"
      region  = "us-central1" # Or your preferred default region
    }

    # Example 1: Creating a standard bucket with versioning enabled
    module "app_logs_bucket" {
      source = "./modules/gcs_bucket" # Path to your local module

      bucket_name     = "my-application-logs-unique-name" # MUST be globally unique
      location        = "US-CENTRAL1"
      storage_class   = "STANDARD"
      enable_versioning = true
      labels = {
        environment = "development"
        application = "my-app"
      }
    }

    # Example 2: Creating an archive bucket for long-term storage
    module "archive_data_bucket" {
      source = "./modules/gcs_bucket"

      bucket_name     = "my-long-term-archive-unique-name" # MUST be globally unique
      location        = "EUROPE-WEST2"
      storage_class   = "ARCHIVE"
      enable_versioning = false # Versioning may not be necessary for immutable archives, saving cost
      uniform_bucket_level_access = true # Still good practice
    }

    # Example 3: Deploying to a specific project explicitly
