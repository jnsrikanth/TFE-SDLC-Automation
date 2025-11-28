Okay, Architect! This is a well-designed and reusable Terraform module for creating GCS buckets. Now, let's craft the Terratest code to validate its functionality and ensure it behaves as expected.

---

## Terratest for `gcs_bucket` Module

This Terratest code will:

1.  **Set up a temporary Terraform environment.**
2.  **Deploy the `gcs_bucket` module with different configurations.**
3.  **Verify the created GCS bucket's properties** using the Google Cloud client libraries.
4.  **Clean up the created resources** after the tests.

---

### Terratest Setup

Before running the Terratest code, ensure you have the following:

1.  **Go installed:** You'll need Go to run the Terratest code.
2.  **Google Cloud credentials configured:** Terratest will use your existing `gcloud` credentials or environment variables for authentication.
3.  **Terraform installed:** Terratest executes Terraform commands.
4.  **Google Cloud Storage client library for Go:** Install it using:
    ```bash
    go get cloud.google.com/go/storage
    ```

---

### Terratest File: `test/gcs_bucket_test.go`

Create a new directory named `test` at the root of your Terraform project (next to your `modules` directory). Inside the `test` directory, create a file named `gcs_bucket_test.go`.

```go
// test/gcs_bucket_test.go

package test

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/google"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/uuid"
	"google.golang.org/api/iterator"
	storage "cloud.google.com/go/storage"
)

// Global variables for common test parameters
var (
	gcpProjectID   = os.Getenv("GCP_PROJECT_ID") // Ensure this is set in your environment or replace with your project ID
	gcpRegion      = os.Getenv("GCP_REGION")   // Ensure this is set in your environment or replace with your region
	gcpZone        = os.Getenv("GCP_ZONE")     // Ensure this is set in your environment or replace with your zone
	moduleDir      = filepath.Join("..", "modules", "gcs_bucket")
	testDir        = filepath.Join("..", "test")
)

func init() {
	// Set defaults if environment variables are not set
	if gcpProjectID == "" {
		// Attempt to get from gcloud config if available
		gcpProjectID = google.GetGoogleProjectIDForTest()
		if gcpProjectID == "" {
			panic("GCP_PROJECT_ID environment variable is not set and could not be determined from gcloud config. Please set it.")
		}
	}
	if gcpRegion == "" {
		gcpRegion = "us-central1" // Default region
	}
	if gcpZone == "" {
		gcpZone = "us-central1-a" // Default zone
	}
	logger.Logf( "Using GCP Project ID: %s", gcpProjectID)
	logger.Logf( "Using GCP Region: %s", gcpRegion)
	logger.Logf( "Using GCP Zone: %s", gcpZone)
}

// TestGcsBucketBasicCreation tests the basic creation of a GCS bucket.
func TestGcsBucketBasicCreation(t *testing.T) {
	t.Parallel()

	// Generate a unique bucket name to avoid conflicts
	bucketName := fmt.Sprintf("terratest-gcs-basic-%s", uuid.UniqueId())
	logger.Logf( "Testing basic GCS bucket creation with name: %s", bucketName)

	// Define Terraform options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: testDir, // Directory containing root terraform files for testing
		Vars: map[string]interface{}{
			"bucket_name":     bucketName,
			"location":        "US",
			"storage_class":   "STANDARD",
			"enable_versioning": false,
			"project_id":      gcpProjectID,
		},
		// We need to define the module source in the root test config to be able to reference it
		// This is a common pattern for testing modules in Terratest
		BackendConfig: map[string]interface{}{
			"bucket":  fmt.Sprintf("terratest-terraform-state-%s", uuid.UniqueId()), // Unique backend bucket
			"region":  gcpRegion,
			"project": gcpProjectID,
		},
	})

	// Clean up the backend bucket if it exists from a previous run
	defer func() {
		// This cleanup is a bit tricky as we don't have the exact backend bucket name beforehand.
		// A more robust approach would be to create a separate test for backend setup/teardown.
		// For simplicity here, we'll skip explicit backend cleanup in the defer block,
		// assuming a new unique backend bucket is created each time.
	}()

	// Deploy the module
	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Verify bucket properties using Google Cloud client library
	client, err := storage.NewClient(terraformOptions.Context) // Use context from terraform options
	if err != nil {
		t.Fatalf("Failed to create GCS client: %v", err)
	}
	defer client.Close()

	// Get the bucket object
	bucket := client.Bucket(bucketName)
	attrs, err := bucket.Attrs(terraformOptions.Context)
	if err != nil {
		t.Fatalf("Failed to get bucket attributes for %s: %v", bucketName, err)
	}

	// Assertions
	if attrs.Name != bucketName {
		t.Errorf("Expected bucket name %q, but got %q", bucketName, attrs.Name)
	}
	if attrs.Location != "US" {
		t.Errorf("Expected bucket location %q, but got %q", "US", attrs.Location)
	}
	if attrs.StorageClass != "STANDARD" {
		t.Errorf("Expected bucket storage class %q, but got %q", "STANDARD", attrs.StorageClass)
	}
	if attrs.VersioningEnabled != false {
		t.Errorf("Expected versioning to be disabled, but it was enabled")
	}
	if attrs.UniformBucketLevelAccess != true {
		t.Errorf("Expected uniform bucket-level access to be enabled, but it was disabled")
	}
}

// TestGcsBucketWithVersioning tests GCS bucket creation with versioning enabled.
func TestGcsBucketWithVersioning(t *testing.T) {
	t.Parallel()

	bucketName := fmt.Sprintf("terratest-gcs-versioning-%s", uuid.UniqueId())
	logger.Logf( "Testing GCS bucket creation with versioning enabled for name: %s", bucketName)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: testDir,
		Vars: map[string]interface{}{
			"bucket_name":     bucketName,
			"location":        "US-CENTRAL1",
			"storage_class":   "NEARLINE",
			"enable_versioning": true,
			"project_id":      gcpProjectID,
		},
		BackendConfig: map[string]interface{}{
			"bucket":  fmt.Sprintf("terratest-terraform-state-%s", uuid.UniqueId()),
			"region":  gcpRegion,
			"project": gcpProjectID,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	client, err := storage.NewClient(terraformOptions.Context)
	if err != nil {
		t.Fatalf("Failed to create GCS client: %v", err)
	}
	defer client.Close()

	bucket := client.Bucket(bucketName)
	attrs, err := bucket.Attrs(terraformOptions.Context)
	if err != nil {
		t.Fatalf("Failed to get bucket attributes for %s: %v", bucketName, err)
	}

	if attrs.Name != bucketName {
		t.Errorf("Expected