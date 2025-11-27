# ==============================================================================
# CLUSTER OUTPUTS
# ==============================================================================

output "cluster_id" {
  description = "The Kubernetes Managed Cluster ID"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  description = "The FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

output "cluster_private_fqdn" {
  description = "The private FQDN of the AKS cluster (if private cluster enabled)"
  value       = azurerm_kubernetes_cluster.main.private_fqdn
}

output "kubernetes_version" {
  description = "The Kubernetes version deployed"
  value       = azurerm_kubernetes_cluster.main.kubernetes_version
}

output "node_resource_group" {
  description = "The auto-generated resource group which contains the AKS cluster resources"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

# ==============================================================================
# KUBECONFIG & ACCESS
# ==============================================================================

output "kube_config" {
  description = "Raw kubeconfig for cluster access"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "kube_admin_config" {
  description = "Raw kubeconfig for cluster admin access"
  value       = azurerm_kubernetes_cluster.main.kube_admin_config_raw
  sensitive   = true
}

output "client_certificate" {
  description = "Base64 encoded public certificate used by clients to authenticate to the cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_certificate
  sensitive   = true
}

output "client_key" {
  description = "Base64 encoded private key used by clients to authenticate to the cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_key
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64 encoded public CA certificate used as the root of trust for the cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "host" {
  description = "The Kubernetes cluster server host"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive   = true
}

# ==============================================================================
# IDENTITY OUTPUTS
# ==============================================================================

output "kubelet_identity" {
  description = "The kubelet identity object"
  value = {
    client_id                 = azurerm_kubernetes_cluster.main.kubelet_identity[0].client_id
    object_id                 = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
    user_assigned_identity_id = azurerm_kubernetes_cluster.main.kubelet_identity[0].user_assigned_identity_id
  }
}

output "cluster_identity_principal_id" {
  description = "The principal ID of the cluster's managed identity"
  value       = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

output "cluster_identity_tenant_id" {
  description = "The tenant ID of the cluster's managed identity"
  value       = azurerm_kubernetes_cluster.main.identity[0].tenant_id
}

# ==============================================================================
# NETWORKING OUTPUTS
# ==============================================================================

output "network_profile" {
  description = "The network profile of the AKS cluster"
  value = {
    network_plugin     = azurerm_kubernetes_cluster.main.network_profile[0].network_plugin
    network_policy     = azurerm_kubernetes_cluster.main.network_profile[0].network_policy
    service_cidr       = azurerm_kubernetes_cluster.main.network_profile[0].service_cidr
    dns_service_ip     = azurerm_kubernetes_cluster.main.network_profile[0].dns_service_ip
    docker_bridge_cidr = azurerm_kubernetes_cluster.main.network_profile[0].docker_bridge_cidr
    pod_cidr           = azurerm_kubernetes_cluster.main.network_profile[0].pod_cidr
  }
}

output "effective_outbound_ips" {
  description = "The effective outbound IP addresses of the cluster"
  value       = try(azurerm_kubernetes_cluster.main.network_profile[0].load_balancer_profile[0].effective_outbound_ips, [])
}

# ==============================================================================
# NODE POOL OUTPUTS
# ==============================================================================

output "default_node_pool_id" {
  description = "The ID of the default node pool"
  value       = azurerm_kubernetes_cluster.main.default_node_pool[0].name
}

output "additional_node_pool_ids" {
  description = "Map of additional node pool names to their IDs"
  value       = { for k, v in azurerm_kubernetes_cluster_node_pool.additional : k => v.id }
}

output "additional_node_pool_status" {
  description = "Status information for additional node pools"
  value = {
    for k, v in azurerm_kubernetes_cluster_node_pool.additional : k => {
      id               = v.id
      vm_size          = v.vm_size
      node_count       = v.node_count
      auto_scaling     = v.enable_auto_scaling
      availability_zones = v.zones
    }
  }
}

# ==============================================================================
# MONITORING & ADD-ONS OUTPUTS
# ==============================================================================

output "oms_agent_identity" {
  description = "The OMS agent identity (if enabled)"
  value = var.enable_container_insights ? {
    client_id                 = try(azurerm_kubernetes_cluster.main.oms_agent[0].oms_agent_identity[0].client_id, null)
    object_id                 = try(azurerm_kubernetes_cluster.main.oms_agent[0].oms_agent_identity[0].object_id, null)
    user_assigned_identity_id = try(azurerm_kubernetes_cluster.main.oms_agent[0].oms_agent_identity[0].user_assigned_identity_id, null)
  } : null
}

output "key_vault_secrets_provider_identity" {
  description = "The Key Vault Secrets Provider identity (if enabled)"
  value = var.key_vault_secrets_provider_enabled ? {
    client_id = try(azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].client_id, null)
    object_id = try(azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].object_id, null)
  } : null
}

output "azure_policy_enabled" {
  description = "Whether Azure Policy is enabled"
  value       = var.enable_azure_policy
}

output "defender_enabled" {
  description = "Whether Microsoft Defender for Containers is enabled"
  value       = var.enable_defender
}

# ==============================================================================
# PORTAL ACCESS OUTPUT
# ==============================================================================

output "portal_url" {
  description = "URL to access the AKS cluster in Azure Portal"
  value       = "https://portal.azure.com/#resource${azurerm_kubernetes_cluster.main.id}"
}

# ==============================================================================
# KUBECTL COMMAND HELPERS
# ==============================================================================

output "get_credentials_command" {
  description = "Command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${var.resource_group_name} --name ${var.cluster_name}"
}

output "get_admin_credentials_command" {
  description = "Command to get AKS admin credentials (if local accounts not disabled)"
  value       = var.local_account_disabled ? "N/A - Local accounts are disabled" : "az aks get-credentials --resource-group ${var.resource_group_name} --name ${var.cluster_name} --admin"
}
