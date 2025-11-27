locals {
  # Cluster identification
  cluster_id = "${var.cluster_name}-${var.location}"

  # Node pool configuration helpers
  system_node_pool_name = var.default_node_pool.name

  # Network configuration
  is_azure_cni = var.network_plugin == "azure"

  # RBAC configuration
  enable_aad_integration = var.azure_rbac_managed || length(var.admin_group_object_ids) > 0

  # Monitoring configuration
  enable_monitoring = var.enable_container_insights && var.log_analytics_workspace_id != null

  # Security configurations
  security_features = {
    azure_policy_enabled       = var.enable_azure_policy
    defender_enabled           = var.enable_defender
    key_vault_provider_enabled = var.key_vault_secrets_provider_enabled
    private_cluster            = var.enable_private_cluster
  }

  # Resource naming
  node_resource_group = var.node_resource_group_name != null ? var.node_resource_group_name : "MC_${var.resource_group_name}_${var.cluster_name}_${var.location}"

  # Common tags
  common_tags = merge(
    var.tags,
    {
      "managed-by"       = "terraform"
      "cluster-name"     = var.cluster_name
      "environment-type" = lookup(var.tags, "environment", "production")
      "deployment-date"  = timestamp()
    }
  )

  # Auto-scaler profile configuration
  auto_scaler_enabled = var.enable_auto_scaling && var.default_node_pool.enable_auto_scaling
}
