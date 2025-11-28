Okay, Architect! This is a well-designed Terraform module for creating a GCS bucket. Now, let's write some Terratest code to ensure its robustness and correctness.

Terratest is a Go library that helps you write automated tests for your infrastructure code. It can:

*   Deploy your Terraform code.
*   Make assertions about the deployed resources.
*   Clean up resources after the test.

Here's a Terratest setup to test your `gcs-bucket` module:

---

### 1. Project Structure for Terratest

Create a new directory for your Terratest tests, typically at the root of your Terraform module or in a separate `test` directory.

```
.
├── gcs-bucket/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
└── test/
    └── gcs-bucket_test.go
```

---

### 2. Terratest Code (`test/gcs-bucket_test.go`)

```go
package test

import (
	"fmt"
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Terraform will be executed in a temporary directory with the given files.
// We'll use the local module for testing.
var terraformDir = "../gcs-bucket"

// TestGCSBucketCreation tests the basic creation of a GCS bucket.
func TestGCSBucketCreation(t *testing.T) {
	// Define unique bucket name for the test
	// GCS bucket names must be globally unique, so appending a timestamp or random string is crucial.
	// For simplicity here, we'll use a fixed prefix and let Terraform apply to handle uniqueness.
	// In a real-world scenario, you might want to generate a truly random suffix.
	testBucketName := fmt.Sprintf("terratest-gcs-bucket-%s", strings.ToLower(os.Getenv("USER"))) // Using USER env var for some uniqueness

	// Define Terraform options
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: terraformDir,

		// Variables to pass to our Terraform code
		Vars: map[string]interface{}{
			"bucket_name": testBucketName,
			"location":    "US-WEST1",
			"storage_class": "NEARLINE",
			"labels": map[string]string{
				"test_env": "terratest",
			},
		},

		// Enable this to debug Terraform output
		// Debug: true,
	}

	// Clean up resources after the test runs, even if it fails.
	defer terraform.Destroy(t, terraformOptions)

	// Apply the Terraform code to create the GCS bucket
	terraform.InitAndApply(t, terraformOptions)

	// --- Assertions ---

	// 1. Verify bucket name
	actualBucketName := terraform.Output(t, terraformOptions, "bucket_name")
	assert.Equal(t, testBucketName, actualBucketName, "Bucket name mismatch.")

	// 2. Verify bucket URL (gsutil URI)
	actualBucketURL := terraform.Output(t, terraformOptions, "bucket_url")
	expectedBucketURL := fmt.Sprintf("gs://%s", testBucketName)
	assert.Equal(t, expectedBucketURL, actualBucketURL, "Bucket URL mismatch.")

	// 3. Verify bucket self-link
	actualBucketSelfLink := terraform.Output(t, terraformOptions, "bucket_self_link")
	// The self-link format is generally like: "https://www.googleapis.com/storage/v1/b/your-bucket-name"
	assert.True(t, strings.HasSuffix(actualBucketSelfLink, testBucketName), "Bucket self-link does not contain bucket name.")
	assert.Contains(t, actualBucketSelfLink, "googleapis.com/storage/v1/b/", "Bucket self-link has unexpected format.")

	// Additional checks can be made using the Google Cloud client libraries if needed,
	// but for this module, checking outputs is a good start.
}

// TestGCSBucketVersioning tests the creation of a GCS bucket with versioning enabled.
func TestGCSBucketVersioning(t *testing.T) {
	testBucketName := fmt.Sprintf("terratest-gcs-bucket-versioning-%s", strings.ToLower(os.Getenv("USER")))

	terraformOptions := &terraform.Options{
		TerraformDir: terraformDir,
		Vars: map[string]interface{}{
			"bucket_name": testBucketName,
			"location":    "ASIA-SOUTHEAST1",
			"versioning": map[string]bool{
				"enabled": true,
			},
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify that versioning is enabled.
	// This requires fetching the actual bucket resource details.
	// For simplicity, we'll rely on Terraform's state and outputs if available,
	// or use a client library for more direct verification.
	// The current module doesn't expose versioning status as an output, so this is a conceptual check.
	// If you added a versioning_enabled output, you could assert it here.
	// For now, we assume if Apply succeeds with versioning=true, it's configured.
	// A more robust test would involve calling the GCS API directly.

	// Example of how you *might* check (if you had a way to get the bucket object from state or API):
	// bucket, err := getBucketFromTerraformState(t, terraformOptions, testBucketName)
	// assert.NoError(t, err)
	// assert.True(t, bucket.VersioningEnabled, "Versioning should be enabled")

	t.Logf("Successfully created bucket with versioning enabled: %s", testBucketName)
}

// TestGCSBucketWebsiteHosting tests the creation of a GCS bucket with website hosting configured.
func TestGCSBucketWebsiteHosting(t *testing.T) {
	testBucketName := fmt.Sprintf("terratest-gcs-bucket-website-%s", strings.ToLower(os.Getenv("USER")))

	terraformOptions := &terraform.Options{
		TerraformDir: terraformDir,
		Vars: map[string]interface{}{
			"bucket_name": testBucketName,
			"location":    "EUROPE-WEST2",
			"website": map[string]string{
				"main_page_suffix": "index.html",
				"not_found_page":   "404.html",
			},
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Similar to versioning, directly verifying website configuration from Terraform state
	// can be tricky. A more direct API call would be ideal.
	// For this module, we'll assume a successful apply with the website variable means it's configured.

	t.Logf("Successfully created bucket with website hosting enabled: %s", testBucketName)
}

// TestGCSBucketForceDestroy tests that force_destroy works as expected.
// This test should be carefully considered in a production pipeline.
func TestGCSBucketForceDestroy(t *testing.T) {
	testBucketName := fmt.Sprintf("terratest-gcs-bucket-forcedestroy-%s", strings.ToLower(os.Getenv("USER")))

	terraformOptions := &terraform.Options{
		TerraformDir: terraformDir,
		Vars: map[string]interface{}{
			"bucket_name":     testBucketName,
			"location":        "US-EAST1",
			"force_destroy":   true, // Crucial for this test
			"storage_class": "ARCHIVE", // Using a less common class to ensure it works
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	// Apply to create the bucket
	terraform.InitAndApply(t, terraformOptions)

	// Now, we'll simulate destroying the bucket even if it had content.
	// The `force_destroy = true` should prevent Terraform from failing.
	// In a real scenario, you might upload a dummy file first to prove it.
	// For this test, we'll just confirm that `Destroy` runs without error.
	t.Logf("Bucket created with force_destroy enabled: %s. Will now destroy.", testBucketName)

	// Terraform Destroy will be called by the defer statement.
	// If `force_destroy` was `false` and the bucket had contents (which it doesn't in this minimal test),
	// `terraform.