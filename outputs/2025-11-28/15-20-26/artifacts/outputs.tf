```hcl
# outputs.tf

# ------------------------------------------------------------------------------
# Cluster Identification Outputs
# ------------------------------------------------------------------------------

output "cluster_id" {
  description = "The unique identifier of the Kubernetes cluster."
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "The name of the Kubernetes cluster."
  value       = azurerm_kubernetes_cluster.this.name
}

output "cluster_fqdn" {
  description = "The fully qualified domain name (FQDN) of the Kubernetes cluster."
  value       = azurerm_kubernetes_cluster.this.kube_config.host
}

output "cluster_private_fqdn" {
  description = "The private fully qualified domain name (FQDN) of the Kubernetes cluster. This is only available if private cluster is enabled."
  value       = azurerm_kubernetes_cluster.this.private_cluster_enabled ? azurerm_kubernetes_cluster.this.private_cluster_identity[0].public_endpoint : null
}

# ------------------------------------------------------------------------------
# Cluster Access Outputs (Sensitive)
# ------------------------------------------------------------------------------

output "kubeconfig" {
  description = "The kubeconfig for accessing the Kubernetes cluster. This is sensitive information."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "cluster_certificate_authority_data" {
  description = "The cluster's certificate authority data. This is sensitive information."
  value       = azurerm_kubernetes_cluster.this.kube_config.cluster_ca_certificate
  sensitive   = true
}

# ------------------------------------------------------------------------------
# Cluster Identity Outputs
# ------------------------------------------------------------------------------

output "cluster_identity_type" {
  description = "The type of the cluster's identity (e.g., `systemAssigned`, `userAssigned`)."
  value       = azurerm_kubernetes_cluster.this.identity.type
}

output "cluster_principal_id" {
  description = "The principal ID of the cluster's identity. This is the object ID."
  value       = azurerm_kubernetes_cluster.this.identity.principal_id
}

output "cluster_tenant_id" {
  description = "The tenant ID of the cluster's identity."
  value       = azurerm_kubernetes_cluster.this.identity.tenant_id
}

output "oms_agent_identity_principal_id" {
  description = "The principal ID of the Managed Identity used by the OMS agent for monitoring. This is only available if OMS agent is enabled."
  value       = azurerm_kubernetes_cluster.this.oms_agent.0.oms_agent_identity_id
  depends_on  = [azurerm_kubernetes_cluster.this] # Ensure OMS agent configuration is applied
}

output "key_vault_identity_principal_id" {
  description = "The principal ID of the Managed Identity used for Key Vault integration. This is only available if Key Vault integration is enabled."
  value       = azurerm_kubernetes_cluster.this.key_vault_secrets_provider.0.secret_rotation_identity_id
  depends_on  = [azurerm_kubernetes_cluster.this] # Ensure Key Vault integration is applied
}

# ------------------------------------------------------------------------------
# Network Profile Outputs
# ------------------------------------------------------------------------------

output "network_profile" {
  description = "A map containing the cluster's network profile configuration."
  value       = {
    network_plugin                 = azurerm_kubernetes_cluster.this.network_profile[0].network_plugin
    network_mode                   = azurerm_kubernetes_cluster.this.network_profile[0].network_mode
    dns_service_ip                 = azurerm_kubernetes_cluster.this.network_profile[0].dns_service_ip
    docker_bridge_cidr             = azurerm_kubernetes_cluster.this.network_profile[0].docker_bridge_cidr
    service_cidr                   = azurerm_kubernetes_cluster.this.network_profile[0].service_cidr
    pod_cidr                       = azurerm_kubernetes_cluster.this.network_profile[0].pod_cidr
    load_balancer_sku              = azurerm_kubernetes_cluster.this.network_profile[0].load_balancer_sku
    vnet_subnet_id                 = azurerm_kubernetes_cluster.this.network_profile[0].vnet_subnet_id
    private_cluster_enabled        = azurerm_kubernetes_cluster.this.network_profile[0].private_cluster_enabled
    private_dns_zone               = azurerm_kubernetes_cluster.this.network_profile[0].private_dns_zone
    http_application_routing_enabled = azurerm_kubernetes_cluster.this.network_profile[0].http_application_routing_enabled
    outbound_type                  = azurerm_kubernetes_cluster.this.network_profile[0].outbound_type
    outbound_ip_addresses          = azurerm_kubernetes_cluster.this.network_profile[0].outbound_ip_addresses
    ip_ranges_to_exclude           = azurerm_kubernetes_cluster.this.network_profile[0].ip_ranges_to_exclude
  }
}

# ------------------------------------------------------------------------------
# Node Pool Outputs
# ------------------------------------------------------------------------------

output "default_node_pool" {
  description = "Details of the default node pool."
  value       = {
    name                       = azurerm_kubernetes_cluster.this.default_node_pool[0].name
    vm_size                    = azurerm_kubernetes_cluster.this.default_node_pool[0].vm_size
    enable_auto_scaling        = azurerm_kubernetes_cluster.this.default_node_pool[0].enable_auto_scaling
    min_count                  = azurerm_kubernetes_cluster.this.default_node_pool[0].min_count
    max_count                  = azurerm_kubernetes_cluster.this.default_node_pool[0].max_count
    node_count                 = azurerm_kubernetes_cluster.this.default_node_pool[0].node_count
    os_disk_size_gb            = azurerm_kubernetes_cluster.this.default_node_pool[0].os_disk_size_gb
    os_type                    = azurerm_kubernetes_cluster.this.default_node_pool[0].os_type
    vnet_subnet_id             = azurerm_kubernetes_cluster.this.default_node_pool[0].vnet_subnet_id
    zones                      = azurerm_kubernetes_cluster.this.default_node_pool[0].zones
    mode                       = azurerm_kubernetes_cluster.this.default_node_pool[0].mode
    tags                       = azurerm_kubernetes_cluster.this.default_node_pool[0].tags
    node_labels                = azurerm_kubernetes_cluster.this.default_node_pool[0].node_labels
    node_taints                = azurerm_kubernetes_cluster.this.default_node_pool[0].node_taints
    priority                   = azurerm_kubernetes_cluster.this.default_node_pool[0].priority
    enable_node_public_ip      = azurerm_kubernetes_cluster.this.default_node_pool[0].enable_node_public_ip
    max_pods                   = azurerm_kubernetes_cluster.this.default_node_pool[0].max_pods
    kubelet_disk_type          = azurerm_kubernetes_cluster.this.default_node_pool[0].kubelet_disk_type
  }
}

output "additional_node_pools" {
  description = "A list of additional node pools configured for the cluster. Each item contains details about a node pool."
  value       = [
    for pool in azurerm_kubernetes_cluster_node_pool.additional : {
      name                       = pool.name
      vm_size                    = pool.vm_size
      enable_auto_scaling        = pool.enable_auto_scaling
      min_count                  = pool.min_count
      max_count                  = pool.max_count
      node_count                 = pool.node_count
      os_disk_size_gb            = pool.os_disk_size_gb
      os_type                    = pool.os_type
      vnet_subnet_id             = pool.vnet_subnet_id
      zones                      = pool.zones
      mode                       = pool.mode
      tags                       = pool.tags
      node_labels                = pool.node_labels
      node_taints                = pool.node_taints
      priority                   = pool.priority
      