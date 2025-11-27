package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestEnterpriseAKSClusterDeployment validates the complete AKS cluster deployment
func TestEnterpriseAKSClusterDeployment(t *testing.T) {
	t.Parallel()

	// Configure Terraform options
	terraformOptions := &terraform.Options{
		TerraformDir: "../",
		Vars: map[string]interface{}{
			"cluster_name":        fmt.Sprintf("aks-test-%s", time.Now().Format("20060102150405")),
			"resource_group_name": "rg-aks-test",
			"location":            "eastus",
			"kubernetes_version":  "1.28.3",
			"vnet_subnet_id":      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-aks/subnets/subnet-aks",
			"tags": map[string]string{
				"environment": "testing",
				"cost-center": "engineering",
			},
		},
		VarFiles: []string{"testfixtures/terraform.tfvars"},
	}

	// Clean up resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Run validation tests
	t.Run("ClusterBasicValidation", func(t *testing.T) {
		testClusterBasicProperties(t, terraformOptions)
	})

	t.Run("NetworkingValidation", func(t *testing.T) {
		testNetworkingConfiguration(t, terraformOptions)
	})

	t.Run("RBACValidation", func(t *testing.T) {
		testRBACConfiguration(t, terraformOptions)
	})

	t.Run("MonitoringValidation", func(t *testing.T) {
		testMonitoringConfiguration(t, terraformOptions)
	})

	t.Run("SecurityValidation", func(t *testing.T) {
		testSecurityFeatures(t, terraformOptions)
	})

	t.Run("NodePoolValidation", func(t *testing.T) {
		testNodePoolConfiguration(t, terraformOptions)
	})

	t.Run("KubernetesConnectivity", func(t *testing.T) {
		testKubernetesConnectivity(t, terraformOptions)
	})
}

// testClusterBasicProperties validates basic cluster properties
func testClusterBasicProperties(t *testing.T, options *terraform.Options) {
	clusterName := terraform.Output(t, options, "cluster_name")
	kubernetesVersion := terraform.Output(t, options, "kubernetes_version")
	resourceGroupName := options.Vars["resource_group_name"].(string)

	// Verify cluster exists
	assert.NotEmpty(t, clusterName, "Cluster name should not be empty")
	assert.Equal(t, options.Vars["cluster_name"], clusterName, "Cluster name should match input")

	// Verify Kubernetes version
	assert.NotEmpty(t, kubernetesVersion, "Kubernetes version should not be empty")
	assert.Equal(t, options.Vars["kubernetes_version"], kubernetesVersion, "Kubernetes version should match input")

	// Get cluster from Azure
	cluster, err := azure.GetManagedClusterE(t, resourceGroupName, clusterName, "")
	require.NoError(t, err, "Failed to get AKS cluster")

	// Validate cluster state
	assert.NotNil(t, cluster, "Cluster should not be nil")
	assert.Equal(t, "Succeeded", *cluster.ProvisioningState, "Cluster provisioning should be successful")
}

// testNetworkingConfiguration validates networking setup
func testNetworkingConfiguration(t *testing.T, options *terraform.Options) {
	networkProfile := terraform.OutputMap(t, options, "network_profile")

	// Verify network plugin
	assert.Equal(t, "azure", networkProfile["network_plugin"], "Network plugin should be Azure CNI")

	// Verify network policy
	assert.NotEmpty(t, networkProfile["network_policy"], "Network policy should be configured")
	assert.Contains(t, []string{"azure", "calico"}, networkProfile["network_policy"], "Network policy should be azure or calico")

	// Verify service CIDR
	assert.NotEmpty(t, networkProfile["service_cidr"], "Service CIDR should be configured")

	// Verify DNS service IP
	assert.NotEmpty(t, networkProfile["dns_service_ip"], "DNS service IP should be configured")
}

// testRBACConfiguration validates RBAC and identity configuration
func testRBACConfiguration(t *testing.T, options *terraform.Options) {
	clusterName := terraform.Output(t, options, "cluster_name")
	resourceGroupName := options.Vars["resource_group_name"].(string)

	// Get cluster
	cluster, err := azure.GetManagedClusterE(t, resourceGroupName, clusterName, "")
	require.NoError(t, err, "Failed to get AKS cluster")

	// Verify AAD integration
	if cluster.AadProfile != nil {
		assert.NotNil(t, cluster.AadProfile.Managed, "AAD should be managed")
		assert.True(t, *cluster.AadProfile.EnableAzureRBAC, "Azure RBAC should be enabled")
	}

	// Verify identity
	assert.NotNil(t, cluster.Identity, "Cluster should have managed identity")
	assert.NotEmpty(t, cluster.Identity.Type, "Identity type should be configured")

	// Verify local accounts disabled
	assert.True(t, *cluster.DisableLocalAccounts, "Local accounts should be disabled for security")
}

// testMonitoringConfiguration validates monitoring and observability
func testMonitoringConfiguration(t *testing.T, options *terraform.Options) {
	clusterName := terraform.Output(t, options, "cluster_name")
	resourceGroupName := options.Vars["resource_group_name"].(string)

	// Get cluster
	cluster, err := azure.GetManagedClusterE(t, resourceGroupName, clusterName, "")
	require.NoError(t, err, "Failed to get AKS cluster")

	// Verify OMS agent (Container Insights)
	if cluster.AddonProfiles != nil {
		omsAgent := cluster.AddonProfiles["omsagent"]
		assert.NotNil(t, omsAgent, "OMS agent addon should be configured")
		assert.True(t, *omsAgent.Enabled, "OMS agent should be enabled")

		if omsAgent.Config != nil {
			assert.NotEmpty(t, omsAgent.Config["logAnalyticsWorkspaceResourceID"], "Log Analytics workspace should be configured")
		}
	}
}

// testSecurityFeatures validates security features
func testSecurityFeatures(t *testing.T, options *terraform.Options) {
	clusterName := terraform.Output(t, options, "cluster_name")
	resourceGroupName := options.Vars["resource_group_name"].(string)

	// Get cluster
	cluster, err := azure.GetManagedClusterE(t, resourceGroupName, clusterName, "")
	require.NoError(t, err, "Failed to get AKS cluster")

	// Verify Azure Policy addon
	if cluster.AddonProfiles != nil {
		azurePolicy := cluster.AddonProfiles["azurepolicy"]
		if azurePolicy != nil {
			assert.True(t, *azurePolicy.Enabled, "Azure Policy should be enabled")
		}

		// Verify Key Vault Secrets Provider
		keyVaultProvider := cluster.AddonProfiles["azureKeyvaultSecretsProvider"]
		if keyVaultProvider != nil {
			assert.True(t, *keyVaultProvider.Enabled, "Key Vault Secrets Provider should be enabled")
		}
	}

	// Verify Microsoft Defender
	if cluster.SecurityProfile != nil && cluster.SecurityProfile.Defender != nil {
		assert.NotNil(t, cluster.SecurityProfile.Defender.LogAnalyticsWorkspaceResourceID, "Defender should be configured with Log Analytics")
	}

	// Verify private cluster (if enabled)
	azurePolicyEnabled := terraform.Output(t, options, "azure_policy_enabled")
	assert.Equal(t, "true", azurePolicyEnabled, "Azure Policy should be enabled")
}

// testNodePoolConfiguration validates node pool setup
func testNodePoolConfiguration(t *testing.T, options *terraform.Options) {
	clusterName := terraform.Output(t, options, "cluster_name")
	resourceGroupName := options.Vars["resource_group_name"].(string)

	// Get cluster
	cluster, err := azure.GetManagedClusterE(t, resourceGroupName, clusterName, "")
	require.NoError(t, err, "Failed to get AKS cluster")

	// Verify default node pool
	assert.NotNil(t, cluster.AgentPoolProfiles, "Agent pool profiles should exist")
	assert.Greater(t, len(*cluster.AgentPoolProfiles), 0, "At least one node pool should exist")

	defaultPool := (*cluster.AgentPoolProfiles)[0]

	// Verify auto-scaling
	assert.NotNil(t, defaultPool.EnableAutoScaling, "Auto-scaling should be configured")
	if *defaultPool.EnableAutoScaling {
		assert.NotNil(t, defaultPool.MinCount, "Min count should be set for auto-scaling")
		assert.NotNil(t, defaultPool.MaxCount, "Max count should be set for auto-scaling")
		assert.Greater(t, *defaultPool.MaxCount, *defaultPool.MinCount, "Max count should be greater than min count")
	}

	// Verify availability zones
	assert.NotEmpty(t, defaultPool.AvailabilityZones, "Availability zones should be configured")
	assert.GreaterOrEqual(t, len(*defaultPool.AvailabilityZones), 2, "Should span multiple availability zones")

	// Verify VM size
	assert.NotEmpty(t, defaultPool.VMSize, "VM size should be specified")

	// Verify OS disk
	assert.NotNil(t, defaultPool.OsDiskSizeGB, "OS disk size should be specified")
	assert.GreaterOrEqual(t, *defaultPool.OsDiskSizeGB, int32(100), "OS disk should be at least 100GB")
}

// testKubernetesConnectivity validates connectivity to Kubernetes API
func testKubernetesConnectivity(t *testing.T, options *terraform.Options) {
	// Get kubeconfig from Terraform output
	kubeconfig := terraform.Output(t, options, "kube_config")
	assert.NotEmpty(t, kubeconfig, "Kubeconfig should not be empty")

	// Create Kubernetes options
	kubectlOptions := k8s.NewKubectlOptions("", kubeconfig, "kube-system")

	// Test connectivity by listing pods in kube-system namespace
	pods := k8s.ListPods(t, kubectlOptions, map[string]string{})
	assert.Greater(t, len(pods), 0, "Should be able to list pods in kube-system namespace")

	// Verify critical system pods are running
	criticalPods := []string{"coredns", "metrics-server", "kube-proxy"}
	runningPods := make(map[string]bool)

	for _, pod := range pods {
		for _, critical := range criticalPods {
			if pod.Status.Phase == "Running" && len(pod.Name) > len(critical) {
				if pod.Name[:len(critical)] == critical {
					runningPods[critical] = true
				}
			}
		}
	}

	assert.True(t, runningPods["coredns"], "CoreDNS pods should be running")
	assert.True(t, runningPods["kube-proxy"], "Kube-proxy pods should be running")
}

// TestAKSClusterUpgrade tests cluster upgrade process
func TestAKSClusterUpgrade(t *testing.T) {
	t.Skip("Skipping upgrade test - requires extended time and resources")

	// This test would validate the cluster upgrade process
	// Including node pool upgrades, surge settings, and version compatibility
}

// TestAKSDisasterRecovery tests backup and restore procedures
func TestAKSDisasterRecovery(t *testing.T) {
	t.Skip("Skipping disaster recovery test - requires Velero setup")

	// This test would validate disaster recovery procedures
	// Including etcd backups, namespace restoration, and PV recovery
}
