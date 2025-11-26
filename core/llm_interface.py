import random

class LLMInterface:
    """
    A simulated LLM interface. In a real scenario, this would call the Gemini API.
    For this demo, we will return structured mock responses based on the prompt context
    to demonstrate the agentic workflow.
    """
    
    def __init__(self, cfg):
        self.cfg = cfg

    def generate(self, prompt: str, context: str = "") -> str:
        """
        Simulates generating text based on a prompt.
        """
        # Simple keyword matching to simulate "intelligence" for the demo
        if "Architect" in context:
            return self._mock_architect_response(prompt)
        elif "Coder" in context:
            return self._mock_coder_response(prompt)
        elif "SecOps" in context:
            return self._mock_secops_response(prompt)
        elif "QA" in context:
            return self._mock_qa_response(prompt)
        elif "Scribe" in context:
            return self._mock_scribe_response(prompt)
        else:
            return "I am ready to help."

    def _mock_architect_response(self, prompt):
        return """
**Module Blueprint: AKS Standard Cluster**

1.  **Resources**:
    *   `azurerm_kubernetes_cluster`: Main AKS cluster.
    *   `azurerm_kubernetes_cluster_node_pool`: Additional node pools.
    *   `azurerm_role_assignment`: RBAC for ACR and KeyVault.
    *   `azurerm_log_analytics_workspace`: Observability.
    
2.  **Variables**:
    *   `cluster_name` (string)
    *   `location` (string)
    *   `resource_group_name` (string)
    *   `dns_prefix` (string)
    *   `node_count` (number)
    *   `vm_size` (string)
    *   `tags` (map)

3.  **Outputs**:
    *   `cluster_id`
    *   `kube_config`
    *   `cluster_fqdn`
"""

    def _mock_coder_response(self, prompt):
        if "main.tf" in prompt:
            return """
resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
"""
        elif "variables.tf" in prompt:
            return """
variable "cluster_name" {
  type        = string
  description = "The name of the AKS cluster"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "dns_prefix" {
  type        = string
  description = "DNS prefix for the cluster"
}

variable "node_count" {
  type        = number
  default     = 3
  description = "Initial node count"
}

variable "vm_size" {
  type        = string
  default     = "Standard_D2_v2"
  description = "VM size for nodes"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to resources"
}
"""
        else:
            return "# Terraform Code Generated"

    def _mock_secops_response(self, prompt):
        if "detect-secrets" in prompt:
            return """
**Secret Scanning Report**
*   [PASSED] No hardcoded secrets found in .tf files.
*   [PASSED] No .env files committed.
"""
        elif "Sentinel" in prompt:
            return """
**Policy as Code Report (Sentinel)**
*   [PASSED] policy-aks-allowed-regions (Hard Mandatory)
*   [PASSED] policy-aks-mandatory-tags (Soft Mandatory)
*   [PASSED] policy-aks-max-nodes (Advisory)
"""
        else:
            return """
**Security Scan Report (SAST)**

1.  **Checkov Scan**:
    *   [PASSED] CKV_AZURE_1: Ensure AKS uses RBAC.
    *   [PASSED] CKV_AZURE_4: Ensure AKS has RBAC enabled.
    *   [WARNING] CKV_AZURE_115: Ensure that AKS uses Azure CNI networking. (Current: Basic) -> *Recommendation: Update network_profile*
    *   [WARNING] CKV_AZURE_117: Ensure that AKS uses disk encryption sets.
"""

    def _mock_qa_response(self, prompt):
        if "terraform-compliance" in prompt:
            return """
Feature: Ensure AKS Cluster Security

    Scenario: Ensure RBAC is enabled
        Given I have resource that supports tags defined
        When it contains tags
        Then it must contain rbac_enabled
        And its value must be true
"""
        else:
            return """
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
"""

    def _mock_scribe_response(self, prompt):
        return """
# AKS Standard Module

This module provisions a standard Azure Kubernetes Service (AKS) cluster with integrated monitoring and security configurations.

## Usage

```hcl
module "aks" {
  source              = "./modules/aks"
  cluster_name        = "my-aks-cluster"
  location            = "eastus"
  resource_group_name = "my-rg"
  dns_prefix          = "myaks"
  node_count          = 3
}
```

## Inputs
| Name | Description | Type | Default |
|------|-------------|------|---------|
| cluster_name | Name of the cluster | string | n/a |
| ... | ... | ... | ... |
"""
