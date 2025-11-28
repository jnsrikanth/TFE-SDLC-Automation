```hcl
# gcs-bucket/variables.tf

variable "bucket_name" {
  description = "The globally unique name for the GCS bucket. Bucket names must be globally unique and follow naming conventions: start with a letter or number, followed by lowercase letters, numbers, underscores, dots, or dashes, and ending with a letter or number. They must be between 3 and 63 characters long."
  type        = string
  validation {
    # Basic validation for bucket names - enforces common GCS naming rules.
    # More comprehensive validation might involve checking length and specific character sets.
    condition     = can(regex("^[a-z0-9][a-z0-9._-]{1,61}[a-z0-9]$", var.bucket_name)) && length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket names must be globally unique, start and end with a letter or number, and contain only lowercase letters, numbers, underscores, dots, or dashes. Length must be between 3 and 63 characters."
  }
}

variable "location" {
  description = "The location for the GCS bucket. See https://cloud.google.com/storage/docs/locations for a list of available locations."
  type        = string
  default     = "US-CENTRAL1" # A sensible default for many use cases.
}

variable "storage_class" {
  description = "The storage class for the GCS bucket. Options include: STANDARD, NEARLINE, COLDLINE, ARCHIVE."
  type        = string
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "Invalid storage class. Please choose from: STANDARD, NEARLINE, COLDLINE, ARCHIVE."
  }
}

variable "uniform_bucket_level_access" {
  description = "Enables uniform bucket-level access. This is a recommended security best practice that simplifies access control by managing permissions at the bucket level rather than on individual objects."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "If set to true, Terraform will allow the bucket to be destroyed even if it contains objects. Use with extreme caution as this will permanently delete all contents."
  type        = bool
  default     = false
}

variable "versioning" {
  description = "Configuration for object versioning. When enabled, all new versions of an object are kept. If disabled, all but the latest version of an object is permanently deleted."
  type = object({
    enabled = bool
  })
  default = {
    enabled = false # Default to disabled for simplicity and cost control.
  }
}

variable "labels" {
  description = "A map of key-value labels to assign to the bucket. Labels can be used for organizing resources, filtering, and cost allocation."
  type        = map(string)
  default     = {} # Default to an empty map, meaning no labels are applied by default.
}

variable "website" {
  description = "Optional website configuration for the bucket. This allows the bucket to serve static website content. If not provided, website hosting is not configured."
  type = object({
    main_page_suffix = string
    not_found_page   = string
  })
  default = null # Explicitly null means the website configuration block will not be created.
}
```