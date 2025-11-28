Okay, Architect! Let's design some terraform-compliance features for your `gcs-bucket` module. These features will help ensure your module adheres to best practices and security configurations.

We'll focus on common GCS bucket configurations and security aspects.

**Feature File Structure:**

You'll typically place your feature files in a `.terraform-compliance/features/` directory.

```
.terraform-compliance/
└── features/
    ├── gcs-bucket/
    │   ├── bucket_access.feature
    │   ├── bucket_configuration.feature
    │   ├── bucket_naming.feature
    │   └── bucket_security.feature
    └── common/
        └── ... (other common features)
```

---

### `.terraform-compliance/features/gcs-bucket/bucket_access.feature`

This feature focuses on ensuring that access controls are configured appropriately, specifically for uniform bucket-level access.

```gherkin
Feature: GCS Bucket Access Controls

  Scenario: Uniform bucket-level access is enabled by default
    Given a module named "gcs-bucket"
    When I scan the module
    Then the resource "google_storage_bucket.this" should have attribute "uniform_bucket_level_access" set to true

  Scenario: Uniform bucket-level access can be disabled if explicitly intended
    Given a module named "gcs-bucket"
    And I define a variable "uniform_bucket_level_access" with value false
    When I scan the module
    Then the resource "google_storage_bucket.this" should have attribute "uniform_bucket_level_access" set to false

  # Add more scenarios for specific IAM policies if your module evolves to manage them
```

**Explanation:**

*   **`Scenario: Uniform bucket-level access is enabled by default`**: This is a crucial security best practice. This feature checks that the default behavior of your module enforces this.
*   **`Scenario: Uniform bucket-level access can be disabled if explicitly intended`**: This allows for flexibility but ensures that disabling it is a conscious decision by the user of the module.

---

### `.terraform-compliance/features/gcs-bucket/bucket_configuration.feature`

This feature checks for essential configuration parameters like location and storage class.

```gherkin
Feature: GCS Bucket Core Configuration

  Scenario: Bucket must have a specified location
    Given a module named "gcs-bucket"
    And I define a variable "location" with value "US-CENTRAL1"
    When I scan the module
    Then the resource "google_storage_bucket.this" should have attribute "location" set to "US-CENTRAL1"

  Scenario: Bucket must have a specified storage class
    Given a module named "gcs-bucket"
    And I define a variable "storage_class" with value "STANDARD"
    When I scan the module
    Then the resource "google_storage_bucket.this" should have attribute "storage_class" set to "STANDARD"

  Scenario: Bucket can be configured with a different storage class
    Given a module named "gcs-bucket"
    And I define a variable "storage_class" with value "NEARLINE"
    When I scan the module
    Then the resource "google_storage_bucket.this" should have attribute "storage_class" set to "NEARLINE"

  Scenario: Website configuration is optional and correctly applied when present
    Given a module named "gcs-bucket"
    And I define a variable "website" with value { main_page_suffix = "index.html", not_found_page = "404.html" }
    When I scan the module
    Then the resource "google_storage_bucket.this" should have a "website" block
    And the "website" block should have attribute "main_page_suffix" set to "index.html"
    And the "website" block should have attribute "not_found_page" set to "404.html"

  Scenario: Website configuration is omitted when not provided
    Given a module named "gcs-bucket"
    And I define a variable "website" with value null
    When I scan the module
    Then the resource "google_storage_bucket.this" should not have a "website" block
```

**Explanation:**

*   **`Scenario: Bucket must have a specified location`**: Ensures the user provides a location.
*   **`Scenario: Bucket must have a specified storage class`**: Ensures the user provides a storage class.
*   **`Scenario: Bucket can be configured with a different storage class`**: Shows how to test alternative valid configurations.
*   **`Scenario: Website configuration is optional and correctly applied when present`**: Tests the dynamic `website` block.
*   **`Scenario: Website configuration is omitted when not provided`**: Verifies the `null` default for the `website` variable correctly prevents the block from being created.

---

### `.terraform-compliance/features/gcs-bucket/bucket_naming.feature`

This feature validates the naming conventions for GCS buckets.

```gherkin
Feature: GCS Bucket Naming Conventions

  Scenario: Bucket name adheres to basic naming requirements
    Given a module named "gcs-bucket"
    And I define a variable "bucket_name" with value "my-valid-bucket-name-123"
    When I scan the module
    Then the resource "google_storage_bucket.this" should have attribute "name" set to "my-valid-bucket-name-123"

  Scenario: Bucket name fails validation for invalid characters
    Given a module named "gcs-bucket"
    And I define a variable "bucket_name" with value "My_Invalid_Bucket!"
    When I scan the module
    Then the validation for variable "bucket_name" should fail

  Scenario: Bucket name fails validation for incorrect starting/ending characters
    Given a module named "gcs-bucket"
    And I define a variable "bucket_name" with value "123-bucket-name-"
    When I scan the module
    Then the validation for variable "bucket_name" should fail

  Scenario: Bucket name fails validation for excessive length
    Given a module named "gcs-bucket"
    And I define a variable "bucket_name" with value "a-very-long-bucket-name-that-exceeds-the-maximum-allowed-length-of-sixty-three-characters-and-should-fail-validation"
    When I scan the module
    Then the validation for variable "bucket_name" should fail
```

**Explanation:**

*   These scenarios directly test the `validation` block defined in your `variables.tf` for `bucket_name`. This is a powerful way to ensure your module's inputs are validated before Terraform even attempts to plan or apply.

---

### `.terraform-compliance/features/gcs-bucket/bucket_security.feature`

This feature focuses on security-related configurations like `force_destroy` and versioning.

```gherkin
Feature: GCS Bucket Security Settings

  Scenario: Force destroy is disabled by default for safety
    Given a module named "gcs-bucket"
    When I scan the module
    Then the resource "google_storage_bucket.this" should have attribute "force_destroy" set to false

  Scenario: Force destroy can be explicitly enabled with a warning
    Given a module named "gcs-bucket"
    And I define a variable "force_destroy" with value true
    When I scan the module
    Then the resource "google_storage_bucket.this" should have attribute "force_destroy" set to true
    # Optionally, you could add a check for the description of the variable if you want to enforce documentation clarity

  Scenario: Versioning is disabled by default
    Given a module named "gcs-bucket"
    When I scan the module
    Then the resource "google_storage_bucket.this" should have attribute "versioning" equal to { enabled = false }

  Scenario: Versioning can be explicitly enabled
    Given a module named "gcs-bucket"
    And I define a variable "versioning" with value { enabled = true }
    When I scan the module
    Then the resource "google_storage_bucket.this" should have attribute "versioning" equal to { enabled = true }

  Scenario: Labels are applied correctly
    Given a module named "gcs-bucket"
    And I define a variable "labels" with value { environment = "dev", owner = "team-a" }
    When I scan the module
    Then the resource "google_storage_bucket.this" should have attribute "labels" equal to { environment = "dev", owner = "team-a" }

  Scenario: Empty labels map is handled correctly
    Given a module named "gcs-bucket"
    And I define a variable "labels" with value {}
    When I scan the module
    Then the resource "google_storage_bucket.this" should have attribute "labels" equal to {}
```

**Explanation:**

*   **`Scenario: Force destroy is disabled by default for safety`**: Reinforces that `force_destroy` should not be enabled without explicit user intent due to its destructive nature.
