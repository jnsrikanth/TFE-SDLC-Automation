```hcl
# Azure Kubernetes Service (AKS) Enterprise Cluster Configuration

# This Terraform configuration defines an enterprise-grade Azure Kubernetes Service (AKS) cluster.
# It incorporates advanced features for security, scalability, monitoring, and networking.

# --- Provider Configuration ---
# This block configures the Azure provider. Ensure you have authenticated to Azure
# using `az login` or by setting appropriate environment variables (ARM_CLIENT_ID, etc.).
provider "azurerm" {
  features {}
}

# --- Data Sources ---
# These data sources fetch information about existing Azure resources that the AKS cluster will depend on,
# such as the resource group and virtual network/subnet.

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

data "azurerm_subnet" "aks_subnet" {
  name                                           = var.subnet_name
  virtual_network_name                           = data.azurerm_virtual_network.vnet.name
  resource_group_name                            = data.azurerm_resource_group.rg.name
  private_endpoint_network_policies_enabled      = true # Required for Azure CNI with private clusters
  private_link_service_network_policies_enabled  = true # Required for Azure CNI with private clusters
}

# --- AKS Cluster Resource ---
# The core resource for defining the Azure Kubernetes Service cluster.
resource "azurerm_kubernetes_cluster" "enterprise_aks" {
  name                = var.cluster_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "${var.cluster_name}-dns" # Unique DNS prefix for the cluster

  # Enable agent pool profiles. This block defines the initial system node pool.
  # For multi-zone support, specific zones are listed.
  # The system node pool is critical for AKS control plane components and should be highly available.
  agent_pool_profiles {
    name                = "systempool"
    node_count          = var.system_node_pool_count
    vm_size             = var.system_node_pool_vm_size
    os_type             = "Linux"
    os_disk_type        = "Ephemeral" # Ephemeral OS disks offer lower latency and higher throughput for Windows and Linux nodes.
    enable_auto_scaling = var.system_node_pool_enable_auto_scaling
    max_count           = var.system_node_pool_max_count
    min_count           = var.system_node_pool_min_count
    zones               = var.system_node_pool_zones # Multi-zone deployment for high availability
    vnet_subnet_id      = data.azurerm_subnet.aks_subnet.id # Assign to the configured subnet
    mode                = "System" # This is the system node pool, essential for AKS operations.
  }

  # Network profile configuration for Azure CNI.
  # Azure CNI provides direct pod-to-node IP routing and allows pods to get IPs from the VNet.
  # Network policies are enabled for fine-grained network traffic control within the cluster.
  network_profile {
    network_plugin     = "azure" # Use Azure CNI for advanced networking capabilities.
    network_policy     = "azure" # Enable Azure Network Policies for traffic segmentation.
    load_balancer_sku  = "standard" # Standard SKU load balancer is recommended for enterprise features.
    load_balancer_profile {
      outbound_type = "loadBalancer" # Use a load balancer for outbound traffic.
    }
    # For private clusters, you would add `enable_private_cluster = true` and configure private DNS.
    # This example assumes a public cluster for simplicity, but private clusters are a key enterprise feature.
  }

  # Identity configuration for the AKS cluster.
  # System assigned managed identity is recommended for easier management and security.
  identity {
    type = "SystemAssigned"
  }

  # Azure AD integration for RBAC.
  # This allows you to use Azure AD groups and users to manage access to Kubernetes resources.
  # Dynamic blocks are used to conditionally enable/disable these features based on variable values.
  dynamic "azure_active_directory_integration" {
    for_each = var.enable_azure_ad_integration ? [1] : []
    content {
      tenant_id               = var.azure_ad_tenant_id
      client_app_id           = var.azure_ad_client_app_id
      server_app_id           = var.azure_ad_server_app_id
      use_oidc_discovery      = true # Recommended for secure token validation.
      # For role-based access control, you'll typically manage RBAC bindings separately
      # using Kubernetes resources or Terraform's `kubernetes_role_binding` resource.
    }
  }

  # Diagnostic settings for monitoring.
  # Configures sending AKS logs and metrics to Azure Log Analytics Workspace.
  dynamic "oms_agent" {
    for_each = var.enable_oms_agent ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
      # You can specify which logs to collect. Common ones include:
      # container-service-logs, kube-apiserver, kube-controller-manager, etc.
      # For comprehensive logging, consider collecting all available logs.
    }
  }

  # Azure Policy integration for enforcing compliance.
  # This ensures that your cluster adheres to organizational policies.
  dynamic "azure_policy_enabled" {
    for_each = var.enable_azure_policy ? [1] : []
    content {
      enabled = true
    }
  }

  # Azure Defender for Containers integration for security threat detection.
  # Provides enhanced security monitoring and threat detection capabilities.
  # This feature is part of Azure Security Center.
  dynamic "defender_profile" {
    for_each = var.enable_defender ? [1] : []
    content {
      container_runtime_vulnerability_assessment {
        enabled = true
      }
      workload_vulnerability_assessment {
        enabled = true
      }
    }
  }

  # Key Vault Secrets Provider integration.
  # Allows Kubernetes pods to mount secrets stored in Azure Key Vault as volumes.
  dynamic "key_vault_secrets_provider" {
    for_each = var.enable_key_vault_secrets_provider ? [1] : []
    content {
      secret_rotation_enabled = true # Enable automatic secret rotation.
    }
  }

  # Cluster autoscaler configuration.
  # Automatically adjusts the number of nodes in the node pools based on workload demands.
  # This is configured at the cluster level but applies to enabled node pools.
  auto_scaler_profile {
    scan_interval           = var.cluster_autoscaler_scan_interval # How often the autoscaler checks for scaling events.
    scale_down_delay_factor = var.cluster_autoscaler_scale_down_delay_factor # Controls how long the autoscaler waits before removing nodes.
    scale_down_unneeded_time = var.cluster_autoscaler_scale_down_unneeded_time # Time to wait before removing unneeded nodes.
    max_graceful_termination_sec = var.cluster_autoscaler_max_graceful_termination_sec # Max time for pods to terminate gracefully.
    # Other parameters like `expander` can be configured based on specific needs.
  }

  # --- Lifecycle Management ---
  # Ignore changes to specific attributes that are managed by AKS itself or should not be
  # controlled by Terraform after initial creation to avoid conflicts and ensure stability.
  lifecycle {
    ignore_changes = [
      # The `kube_config` attribute is dynamically generated by AKS and should not be managed by Terraform.
      kube_config,
      # `kube_config_raw` is also dynamically generated.
      kube_config_raw,
      # The `sku_tier` can be managed by Terraform but is often updated by Azure for certain features.
      # If you need to explicitly manage SKU tier, remove this ignore.
      sku_tier,
      # `node_resource_group` is automatically created and managed by AKS.
      node_resource_group,
      # `private_cluster_enabled` and related settings might be managed by AKS if using private clusters.
      # If `enable_private_cluster` is set to true in variables, ensure these are handled correctly.
      # For this example assuming public cluster, these are less critical to ignore.
      # private_cluster_enabled,
      # private_cluster_public_fqdn,
      # private_cluster_skip_