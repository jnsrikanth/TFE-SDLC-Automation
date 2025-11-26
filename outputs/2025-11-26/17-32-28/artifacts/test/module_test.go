
package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestAKSModule(t *testing.T) {
	t.Parallel()

	terraformOptions := &terraform.Options{
		TerraformDir: "../output",
		Vars: map[string]interface{}{
			"cluster_name": "test-aks",
			"location":     "eastus",
            "resource_group_name": "rg-test-aks",
            "dns_prefix": "testaks",
		},
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	output := terraform.Output(t, terraformOptions, "cluster_id")
	assert.NotNil(t, output)
}
