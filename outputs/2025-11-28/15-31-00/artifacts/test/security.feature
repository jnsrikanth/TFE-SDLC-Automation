Okay, Architect! Let's design some terraform-compliance features to validate this well-structured GCS bucket module.

Here are the features, categorized for clarity, that you can add to your `.terraform-compliance/features.yml` file.

---

### `.terraform-compliance/features.yml`

```yaml
# .terraform-compliance/features.yml

# --- General Module Configuration ---
- name: GCS Bucket Module - Basic Structure
  description: Verifies the core components of the GCS bucket module are present.
  rules:
    - name: "Module directory exists"
      resource_type: "directory"
      resource_name: "gcs-bucket"
      allow: true
    - name: "main.tf exists"
      resource_type: "file"
      resource_name: "gcs-bucket/main.tf"
      allow: true
    - name: "variables.tf exists"
      resource_type: "file"
      resource_name: "gcs-bucket/variables.tf"
      allow: true
    - name: "outputs.tf exists"
      resource_type: "file"
      resource_name: "gcs-bucket/outputs.tf"
      allow: true
    - name: "README.md exists"
      resource_type: "file"
      resource_name: "gcs-bucket/README.md"
      allow: true

# --- Input Variables Validation ---
- name: GCS Bucket Module - Input Variable Validations
  description: Ensures that input variables have defined validation rules.
  rules:
    - name: "bucket_name - length validation"
      resource_type: "variable"
      resource_name: "bucket_name"
      attribute: "validation.0.condition"
      value: 'length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63'
      operator: "is equal to"
    - name: "bucket_name - character validation"
      resource_type: "variable"
      resource_name: "bucket_name"
      attribute: "validation.1.condition"
      value: 'can(regex("^[a-z0-9][a-z0-9._-]{0,61}[a-z0-9]$", var.bucket_name))'
      operator: "is equal to"
    - name: "storage_class - allowed values validation"
      resource_type: "variable"
      resource_name: "storage_class"
      attribute: "validation.0.condition"
      value: 'contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)'
      operator: "is equal to"

# --- Resource Configuration in main.tf ---
- name: GCS Bucket Module - google_storage_bucket Resource Configuration
  description: Verifies the essential attributes of the google_storage_bucket resource.
  rules:
    - name: "google_storage_bucket - name attribute"
      resource_type: "resource"
      resource_name: "google_storage_bucket.this"
      attribute: "name"
      operator: "is set"
    - name: "google_storage_bucket - location attribute"
      resource_type: "resource"
      resource_name: "google_storage_bucket.this"
      attribute: "location"
      operator: "is set"
    - name: "google_storage_bucket - storage_class attribute"
      resource_type: "resource"
      resource_name: "google_storage_bucket.this"
      attribute: "storage_class"
      operator: "is set"
    - name: "google_storage_bucket - uniform_bucket_level_access attribute"
      resource_type: "resource"
      resource_name: "google_storage_bucket.this"
      attribute: "uniform_bucket_level_access"
      operator: "is set"
    - name: "google_storage_bucket - force_destroy attribute"
      resource_type: "resource"
      resource_name: "google_storage_bucket.this"
      attribute: "force_destroy"
      operator: "is set"
    - name: "google_storage_bucket - labels attribute"
      resource_type: "resource"
      resource_name: "google_storage_bucket.this"
      attribute: "labels"
      operator: "is set"
    - name: "google_storage_bucket - project attribute usage"
      resource_type: "resource"
      resource_name: "google_storage_bucket.this"
      attribute: "project"
      operator: "is set" # This checks if the attribute is present, not its value.
                        # More complex logic for null check would require custom Python.

# --- Output Values ---
- name: GCS Bucket Module - Output Values Defined
  description: Ensures that all defined outputs are present in outputs.tf.
  rules:
    - name: "id output exists"
      resource_type: "output"
      resource_name: "id"
      attribute: "value"
      operator: "is set"
    - name: "name output exists"
      resource_type: "output"
      resource_name: "name"
      attribute: "value"
      operator: "is set"
    - name: "url output exists"
      resource_type: "output"
      resource_name: "url"
      attribute: "value"
      operator: "is set"
    - name: "self_link output exists"
      resource_type: "output"
      resource_name: "self_link"
      attribute: "value"
      operator: "is set"

# --- Default Values Check ---
- name: GCS Bucket Module - Default Values
  description: Verifies that sensible default values are set for optional variables.
  rules:
    - name: "location default value"
      resource_type: "variable"
      resource_name: "location"
      attribute: "default"
      value: "US"
      operator: "is equal to"
    - name: "storage_class default value"
      resource_type: "variable"
      resource_name: "storage_class"
      attribute: "default"
      value: "STANDARD"
      operator: "is equal to"
    - name: "project_id default value"
      resource_type: "variable"
      resource_name: "project_id"
      attribute: "default"
      value: null
      operator: "is equal to"
    - name: "labels default value"
      resource_type: "variable"
      resource_name: "labels"
      attribute: "default"
      value: {}
      operator: "is equal to"
    - name: "uniform_bucket_level_access default value"
      resource_type: "variable"
      resource_name: "uniform_bucket_level_access"
      attribute: "default"
      value: true
      operator: "is equal to"
    - name: "force_destroy default value"
      resource_type: "variable"
      resource_name: "force_destroy"
      attribute: "default"
      value: false
      operator: "is equal to"

# --- Security Best Practices ---
- name: GCS Bucket Module - Security Best Practices
  description: Enforces security-related configurations.
  rules:
    - name: "uniform_bucket_level_access is enabled by default"
      resource_type: "resource"
      resource_name: "google_storage_bucket.this"
      attribute: "uniform_bucket_level_access"
      value: true
      operator: "is equal to"
    # Note: You could add more features here for encryption, logging, etc.
    # if they were part of the module.

# --- README Content Verification (Optional, but good practice) ---
# These checks are more about ensuring the README is useful and matches the code.
# They are more advanced and might require custom Python checks for complex patterns.
# For basic checks, you can look for presence of certain keywords or sections.
- name: GCS Bucket Module - README Content
  description: Basic checks for README content.
  rules:
    - name: "README contains 'Usage' section"
      resource_type: "file"
      resource_name: "gcs-bucket/README.md"
      attribute: "content"
      value: "## Usage"
      operator: "contains"
    - name: "README contains 'Inputs' section"
      resource_type: "file"
      resource_name: "gcs-bucket/README.md"
      attribute: "content"
      value: "## Inputs"
      operator: "contains"
    - name: "README contains 'Outputs' section"
      resource_type: "file"
      resource_name: "gcs-bucket/README.md"
      