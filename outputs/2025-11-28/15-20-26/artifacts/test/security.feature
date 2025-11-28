Okay, Architect! Let's design some terraform-compliance features to validate the `gcs_bucket` module. We'll cover the key features you've outlined.

---

## terraform-compliance Features for `gcs_bucket` Module

Here are the terraform-compliance feature definitions that can be placed in a `.feature` file (e.g., `gcs_bucket.feature`) within your terraform-compliance test directory.

---

### `gcs_bucket.feature`

```gherkin
Feature: GCS Bucket Module Validation

  Scenario: Default bucket configuration with minimal inputs
    Given the following terraform configuration:
      """
      provider "google" {
        project = "test-project"
      }

      module "default_bucket" {
        source = "./modules/gcs_bucket"
        bucket_name = "my-default-bucket-12345"
      }
      """
    Then the resource "module.default_bucket" should have the following attributes:
      | attribute               | value    |
      | location                | "US"     |
      | storage_class           | "STANDARD" |
      | enable_versioning       | false    |
      | uniform_bucket_level_access | true     |
      | labels                  | {}       |
      | project_id              | null     |

  Scenario: Bucket with custom location and storage class
    Given the following terraform configuration:
      """
      provider "google" {
        project = "test-project"
      }

      module "custom_bucket" {
        source = "./modules/gcs_bucket"
        bucket_name     = "my-custom-bucket-67890"
        location        = "ASIA-EAST1"
        storage_class   = "NEARLINE"
      }
      """
    Then the resource "module.custom_bucket" should have the following attributes:
      | attribute     | value    |
      | location      | "ASIA-EAST1" |
      | storage_class | "NEARLINE" |

  Scenario: Bucket with versioning enabled
    Given the following terraform configuration:
      """
      provider "google" {
        project = "test-project"
      }

      module "versioned_bucket" {
        source = "./modules/gcs_bucket"
        bucket_name     = "my-versioned-bucket-abcde"
        enable_versioning = true
      }
      """
    Then the resource "module.versioned_bucket" should have the following attributes:
      | attribute         | value |
      | enable_versioning | true  |

  Scenario: Bucket with custom labels and project ID
    Given the following terraform configuration:
      """
      provider "google" {
        project = "test-project"
      }

      module "labeled_project_bucket" {
        source = "./modules/gcs_bucket"
        bucket_name = "my-labeled-project-bucket-fghij"
        labels = {
          environment = "production"
          app         = "backend"
        }
        project_id = "my-specific-gcp-project"
      }
      """
    Then the resource "module.labeled_project_bucket" should have the following attributes:
      | attribute  | value                                 |
      | labels     | {"environment": "production", "app": "backend"} |
      | project_id | "my-specific-gcp-project"             |

  Scenario: Bucket with disabled uniform bucket-level access
    Given the following terraform configuration:
      """
      provider "google" {
        project = "test-project"
      }

      module "legacy_access_bucket" {
        source = "./modules/gcs_bucket"
        bucket_name     = "my-legacy-access-bucket-klmno"
        uniform_bucket_level_access = false
      }
      """
    Then the resource "module.legacy_access_bucket" should have the following attributes:
      | attribute                       | value |
      | uniform_bucket_level_access | false |

  Scenario: Bucket name validation - too short
    Given the following terraform configuration:
      """
      provider "google" {
        project = "test-project"
      }

      module "short_name_bucket" {
        source = "./modules/gcs_bucket"
        bucket_name = "ab"
      }
      """
    Then the resource "module.short_name_bucket" should be invalid due to validation error.

  Scenario: Bucket name validation - invalid characters
    Given the following terraform configuration:
      """
      provider "google" {
        project = "test-project"
      }

      module "invalid_char_bucket" {
        source = "./modules/gcs_bucket"
        bucket_name = "my_bucket_with_UPPERCASE"
      }
      """
    Then the resource "module.invalid_char_bucket" should be invalid due to validation error.

  Scenario: Storage class validation - invalid class
    Given the following terraform configuration:
      """
      provider "google" {
        project = "test-project"
      }

      module "invalid_storage_bucket" {
        source = "./modules/gcs_bucket"
        bucket_name = "my-invalid-storage-bucket-pqrst"
        storage_class = "INVALID_CLASS"
      }
      """
    Then the resource "module.invalid_storage_bucket" should be invalid due to validation error.

  Scenario: Outputs are correctly defined and accessible
    Given the following terraform configuration:
      """
      provider "google" {
        project = "test-project"
      }

      module "output_bucket" {
        source = "./modules/gcs_bucket"
        bucket_name = "my-output-bucket-uvwxyz"
        location = "US-WEST1"
        storage_class = "COLDLINE"
        enable_versioning = true
      }
      """
    Then the output "module.output_bucket.bucket_id" should be defined.
    And the output "module.output_bucket.bucket_name" should be defined.
    And the output "module.output_bucket.bucket_url" should be defined.
    And the output "module.output_bucket.location" should be defined.
    And the output "module.output_bucket.storage_class" should be defined.
    And the output "module.output_bucket.versioning_enabled" should be defined.
    And the output "module.output_bucket.location" should be equal to "US-WEST1".
    And the output "module.output_bucket.storage_class" should be equal to "COLDLINE".
    And the output "module.output_bucket.versioning_enabled" should be equal to true.

```

---

### Explanation of the Features:

1.  **`Scenario: Default bucket configuration with minimal inputs`**:
    *   Tests the module when only the `bucket_name` is provided.
    *   Verifies that the default values for `location`, `storage_class`, `enable_versioning`, `uniform_bucket_level_access`, `labels`, and `project_id` are correctly applied.

2.  **`Scenario: Bucket with custom location and storage class`**:
    *   Tests providing custom values for `location` and `storage_class`.
    *   Ensures these custom values override the defaults.

3.  **`Scenario: Bucket with versioning enabled`**:
    *   Specifically tests the `enable_versioning` boolean input.

4.  **`Scenario: Bucket with custom labels and project ID`**:
    *   Tests the functionality of adding custom `labels` to the bucket.
    *   Tests providing a specific `project_id` to deploy the bucket into, overriding the provider's default.

5.  **`Scenario: Bucket with disabled uniform bucket-level access`**:
    *   Tests setting `uniform_bucket_level_access` to `false` to ensure the option is respected.

6.  **`Scenario: Bucket name validation - too short`**:
    *   Tests the `validation` block for `bucket_name` to ensure it fails for names shorter than 3 characters.

7.  **`Scenario: Bucket name validation - invalid characters`**:
    *   Tests the `validation` block for `bucket_name` to ensure it fails for names containing invalid characters (e.g., uppercase letters).

8.  **`Scenario: Storage class validation - invalid class`**:
    *   Tests the `validation` block for `storage_class` to ensure it rejects unsupported storage class values.

9.  **`Scenario: Outputs are correctly defined and accessible`**:
    *   This scenario checks that all the defined outputs (`bucket_id`, `bucket_name`, `bucket_url`, `location`, `storage_class`, `versioning_enabled`) are present.
    *   It