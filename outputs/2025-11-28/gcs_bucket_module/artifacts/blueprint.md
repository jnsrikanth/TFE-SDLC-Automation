Okay, Architect! Let's design a Terraform module for creating a simple Google Cloud Storage (GCS) bucket.

**Module Name:** `gcs-bucket`

**Purpose:** To encapsulate the creation of a basic GCS bucket with common configurations, allowing for easy reuse and customization.

**File Structure:**

```
gcs-bucket/
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

**`main.tf` (The Core Logic):**

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

**Explanation of `main.tf`:**

*   **`resource "google_storage_bucket" "this"`:** This is the primary resource block that defines our GCS bucket. The `"this"` is a convention for the primary resource within a module.
*   **`name = var.bucket_name`:** The name of the GCS bucket. This is a required parameter and will be passed in via a variable. Bucket names must be globally unique.
*   **`location = var.location`:** The geographical location where the bucket will be created (e.g., `US-CENTRAL1`, `EUROPE-WEST1`).
*   **`storage_class = var.storage_class`:** The storage class for the bucket (e.g., `STANDARD`, `NEARLINE`, `COLDLINE`, `ARCHIVE`).
*   **`uniform_bucket_level_access = var.uniform_bucket_level_access`:** Controls whether uniform bucket-level access is enabled. This is a recommended security best practice.
*   **`force_destroy = var.force_destroy`:** If set to `true`, Terraform will allow the bucket to be destroyed even if it contains objects. **Use with caution!**
*   **`versioning = var.versioning`:** Configures object versioning for the bucket.
*   **`labels = var.labels`:** Allows you to attach key-value labels to the bucket for organization and cost allocation.
*   **`dynamic "website"`:** This block handles the optional website configuration.
    *   **`for_each = var.website == null ? [] : [var.website]`:** This is a clever way to conditionally create the `website` block. If `var.website` is `null` (meaning it's not provided by the user), the `for_each` will iterate over an empty list, and the `website` block won't be created. If `var.website` is provided, it will iterate over a list containing that single value.
    *   **`content {...}`:** This defines the attributes within the `website` block, which are expected to be provided by the `var.website` variable.

**`variables.tf` (Input Parameters):**

```terraform
# gcs-bucket/variables.tf

variable "bucket_name" {
  description = "The globally unique name for the GCS bucket."
  type        = string
  validation {
    # Basic validation for bucket names - can be expanded
    condition     = can(regex("^[a-z0-9][a-z0-9._-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket names must be globally unique and follow naming conventions."
  }
}

variable "location" {
  description = "The location for the GCS bucket. See https://cloud.google.com/storage/docs/locations"
  type        = string
  default     = "US-CENTRAL1" # A sensible default
}

variable "storage_class" {
  description = "The storage class for the GCS bucket. (e.g., STANDARD, NEARLINE, COLDLINE, ARCHIVE)"
  type        = string
  default     = "STANDARD"
}

variable "uniform_bucket_level_access" {
  description = "Enables uniform bucket-level access. Recommended for security."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "If true, Terraform will allow the bucket to be destroyed even if it contains objects. Use with caution."
  type        = bool
  default     = false
}

variable "versioning" {
  description = "Configuration for object versioning."
  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
}

variable "labels" {
  description = "A map of labels to assign to the bucket."
  type        = map(string)
  default     = {}
}

variable "website" {
  description = "Optional website configuration for the bucket."
  type = object({
    main_page_suffix = string
    not_found_page   = string
  })
  default = null # Explicitly null means not configured
}
```

**Explanation of `variables.tf`:**

*   Each `variable` block defines an input parameter for the module.
*   **`description`:** Provides a human-readable explanation of what the variable is for.
*   **`type`:** Specifies the expected data type (e.g., `string`, `bool`, `map(string)`, `object`).
*   **`default`:** Sets a default value if the user doesn't provide one. This makes the module easier to use for common scenarios.
*   **`validation`:** (For `bucket_name`) Adds basic validation to ensure the input adheres to GCS bucket naming rules. This is a good practice to catch errors early.
*   **`versioning` and `website` types:** These use `object` types to define structured inputs, making it clear what sub-attributes are expected.

**`outputs.tf` (Exposed Information):**

```terraform
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

**Explanation of `outputs.tf`:**

*   `output` blocks expose information about the resources created by the module. This is useful for referencing in other parts of your Terraform configuration.
*   **`bucket_name`:** The actual name of the bucket created.
*   **`bucket_url`:** The `gsutil` URI (e.g., `gs://my-unique-bucket-name`).
*   **`bucket_self_link`:** The API self-link of the bucket resource.

**`README.md` (Documentation):**

```markdown
# Terraform GCS Bucket Module

This module creates a simple Google Cloud Storage (GCS) bucket.

## Features

*   Create a GCS bucket with specified name, location, and storage class.
*   Optionally enable uniform bucket-level access.
*   Optionally enable object versioning.
*   Optionally configure the bucket for static website hosting.
*   Attach labels for organization.
*   Control `force_destroy` behavior for easier cleanup (use with caution).

## Usage

```terraform
module "my_app_bucket" {
  source = "./modules/gcs-bucket" # Or a Git repository URL

  bucket_name = "my-unique-app-data-bucket-12345"
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
}
```