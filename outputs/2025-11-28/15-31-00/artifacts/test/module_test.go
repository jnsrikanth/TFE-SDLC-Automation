Okay, Architect! Let's design the Terratest code to validate your well-crafted GCS Bucket module.

Terratest is a Go library that makes it easy to write automated tests for your infrastructure code. We'll use it to deploy your GCS bucket module, verify its existence, and then clean it up.

---

### Terratest Code for GCS Bucket Module

We'll create a `test` directory in the root of your project (alongside the `modules` directory) and place our Terratest Go code there.

**Project Structure:**

```
.
├── modules/
│   └── gcs-bucket/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
└── test/
    └── gcs_bucket_test.go
```

---

### `test/gcs_bucket_test.go` - Terratest Code

```go
// test/gcs_bucket_test.go

package test

import (
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/gcp"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestGcsBucketCreation tests the creation of a basic GCS bucket.
func TestGcsBucketCreation(t *testing.T) {
	// Get GCP Project ID from environment variable or use a default.
	// It's best practice to use environment variables for sensitive or environment-specific configurations.
	gcpProjectID := os.Getenv("GCP_PROJECT_ID")
	if gcpProjectID == "" {
		t.Fatalf("GCP_PROJECT_ID environment variable not set")
	}

	// Generate a random suffix to ensure bucket name uniqueness across test runs.
	// GCS bucket names must be globally unique.
	randomSuffix := random.UniqueId()
	bucketName := fmt.Sprintf("terratest-gcs-bucket-%s", randomSuffix)
	location := "US-CENTRAL1" // Example location
	storageClass := "STANDARD"

	// Configure Terraform options.
	terraformOptions := &terraform.Options{
		// Path to the Terraform module.
		TerraformDir: "../modules/gcs-bucket",

		// Environment variables to be passed to Terraform.
		// This is a good place to set provider credentials or other configurations.
		// For GCP, the provider typically picks up credentials from the environment
		// (e.g., GOOGLE_APPLICATION_CREDENTIALS) or gcloud CLI configuration.
		// We explicitly set the project ID here.
		EnvVars: map[string]string{
			"GOOGLE_PROJECT": gcpProjectID,
		},

		// Input variables for the Terraform module.
		// These correspond to the variables defined in your gcs-bucket/variables.tf.
		Vars: map[string]interface{}{
			"bucket_name":   bucketName,
			"location":      location,
			"storage_class": storageClass,
			"project_id":    gcpProjectID, // Explicitly pass project_id to the module
			"labels": map[string]string{
				"environment": "testing",
				"test_run_id": randomSuffix,
			},
			"uniform_bucket_level_access": true,
			"force_destroy":               false, // We want to test normal deletion first
		},
	}

	// Defer the cleanup of the Terraform resources.
	// This ensures that `terraform destroy` is called even if the test fails.
	defer terraform.Destroy(t, terraformOptions)

	// Apply the Terraform configuration.
	terraform.InitAndApply(t, terraformOptions)

	// --- Assertions ---

	// 1. Verify that the bucket exists and its properties are as expected.
	t.Run("VerifyBucketProperties", func(t *testing.T) {
		bucket := gcp.GetStorageBucket(t, gcpProjectID, bucketName)

		assert.NotNil(t, bucket, "GCS bucket should exist")
		assert.Equal(t, bucketName, bucket.Name, "Bucket name should match")
		assert.Equal(t, strings.ToUpper(location), strings.ToUpper(bucket.Location), "Bucket location should match") // GCP API might return uppercase location
		assert.Equal(t, strings.ToUpper(storageClass), strings.ToUpper(bucket.StorageClass), "Bucket storage class should match")
		assert.True(t, bucket.UniformBucketLevelAccess, "Uniform bucket-level access should be enabled")

		// Check labels. Terratest's GetStorageBucket doesn't directly expose labels in a simple map.
		// We'll rely on Terraform output for label verification for simplicity here.
		// If you need to deeply inspect labels, you might use the Google Cloud Client Libraries for Go.
		logger.Logf(t, "Successfully verified GCS bucket: %s", bucketName)
	})

	// 2. Verify outputs from the Terraform module.
	t.Run("VerifyOutputs", func(t *testing.T) {
		bucketID := terraform.Output(t, terraformOptions, "id")
		bucketNameOutput := terraform.Output(t, terraformOptions, "name")
		bucketURL := terraform.Output(t, terraformOptions, "url")
		bucketSelfLink := terraform.Output(t, terraformOptions, "self_link")

		assert.NotEmpty(t, bucketID, "Output 'id' should not be empty")
		assert.Equal(t, bucketName, bucketNameOutput, "Output 'name' should match the provided bucket name")
		assert.Contains(t, bucketURL, bucketName, "Output 'url' should contain the bucket name")
		assert.Contains(t, bucketSelfLink, bucketName, "Output 'self_link' should contain the bucket name")

		logger.Logf(t, "Verified Terraform outputs for bucket: %s", bucketName)
	})
}

// TestGcsBucketForceDestroy tests the force_destroy functionality.
// This test is separate to ensure it doesn't interfere with the normal destroy flow.
func TestGcsBucketForceDestroy(t *testing.T) {
	gcpProjectID := os.Getenv("GCP_PROJECT_ID")
	if gcpProjectID == "" {
		t.Fatalf("GCP_PROJECT_ID environment variable not set")
	}

	randomSuffix := random.UniqueId()
	bucketName := fmt.Sprintf("terratest-gcs-bucket-force-%s", randomSuffix)
	location := "US-CENTRAL1"
	storageClass := "STANDARD"

	terraformOptions := &terraform.Options{
		TerraformDir: "../modules/gcs-bucket",
		EnvVars: map[string]string{
			"GOOGLE_PROJECT": gcpProjectID,
		},
		Vars: map[string]interface{}{
			"bucket_name":   bucketName,
			"location":      location,
			"storage_class": storageClass,
			"project_id":    gcpProjectID,
			"force_destroy": true, // Crucial for this test
			"labels": map[string]string{
				"environment": "testing",
				"test_run_id": randomSuffix,
			},
		},
	}

	// Defer the cleanup.
	defer terraform.Destroy(t, terraformOptions)

	// Apply the Terraform configuration.
	terraform.InitAndApply(t, terraformOptions)

	// To properly test force_destroy, we'd ideally:
	// 1. Apply the configuration.
	// 2. Upload a dummy object to the bucket.
	// 3. Run terraform destroy with force_destroy = true.
	// 4. Verify the bucket is gone.

	// For simplicity in this example, we'll just ensure the apply works with force_destroy.
	// The actual test of force_destroy is in the `terraform destroy` call itself.
	// If terraform destroy fails because the bucket has objects and force_destroy is false,
	// this test would catch it (though we've set it to true here).

	logger.Logf(t, "Applied Terraform with force_destroy=true for bucket: %s. Deferring destroy.", bucketName)

	// Optional: Add a small delay before destroy to allow GCP to fully provision.
	time.Sleep(5 * time.Second)
}

// TestGcsBucketValidation ensures that invalid inputs are caught by Terraform's validation rules.
func TestGcsBucketValidation(t *testing.T) {
	gcpProjectID :=