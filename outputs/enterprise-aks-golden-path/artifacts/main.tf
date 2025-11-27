# ==============================================================================
# AZURE KUBERNETES SERVICE (AKS) CLUSTER
# Enterprise-grade AKS cluster with advanced networking, security, and monitoring
# ==============================================================================

resource "azurerm_kubernetes_cluster" "main" {
  name                              = var.cluster_name
  location                          = var.location
  resource_group_name               = var.resource_group_name
  dns_prefix                        = var.cluster_name
  kubernetes_version                = var.kubernetes_version
  node_resource_group               = local.node_resource_group
  automatic_channel_upgrade         = var.automatic_channel_upgrade
  azure_policy_enabled              = var.enable_azure_policy
  http_application_routing_enabled  = var.http_application_routing_enabled
  local_account_disabled            = var.local_account_disabled
  private_cluster_enabled           = var.enable_private_cluster
  private_dns_zone_id               = var.enable_private_cluster ? var.private_dns_zone_id : null

  # ==============================================================================
  # DEFAULT SYSTEM NODE POOL
  # ==============================================================================
  default_node_pool {
    name                = var.default_node_pool.name
    vm_size             = var.default_node_pool.vm_size
    node_count          = var.default_node_pool.enable_auto_scaling ? null : var.default_node_pool.node_count
    min_count           = var.default_node_pool.enable_auto_scaling ? var.default_node_pool.min_count : null
    max_count           = var.default_node_pool.enable_auto_scaling ? var.default_node_pool.max_count : null
    enable_auto_scaling = var.default_node_pool.enable_auto_scaling
    zones               = var.default_node_pool.availability_zones
    max_pods            = var.default_node_pool.max_pods
    os_disk_size_gb     = var.default_node_pool.os_disk_size_gb
    os_disk_type        = var.default_node_pool.os_disk_type
    vnet_subnet_id      = var.vnet_subnet_id
    node_labels         = var.default_node_pool.node_labels
    node_taints         = var.default_node_pool.node_taints

    upgrade_settings {
      max_surge = "33%"
    }
  }

  # ==============================================================================
  # IDENTITY CONFIGURATION
  # ==============================================================================
  identity {
    type         = var.identity_type
    identity_ids = var.identity_type == "UserAssigned" ? [var.user_assigned_identity_id] : null
  }

  # ==============================================================================
  # NETWORK PROFILE
  # ==============================================================================
  network_profile {
    network_plugin     = var.network_plugin
    network_policy     = var.network_policy
    dns_service_ip     = var.dns_service_ip
    docker_bridge_cidr = var.docker_bridge_cidr
    outbound_type      = var.outbound_type
    service_cidr       = var.service_cidr
    load_balancer_sku  = "standard"

    load_balancer_profile {
      managed_outbound_ip_count = 1
      idle_timeout_in_minutes   = 30
    }
  }

  # ==============================================================================
  # AZURE ACTIVE DIRECTORY RBAC INTEGRATION
  # ==============================================================================
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = local.enable_aad_integration ? [1] : []

    content {
      managed                = var.azure_rbac_managed
      azure_rbac_enabled     = var.enable_azure_rbac
      admin_group_object_ids = var.admin_group_object_ids
    }
  }

  # ==============================================================================
  # MONITORING & OBSERVABILITY
  # ==============================================================================
  dynamic "oms_agent" {
    for_each = local.enable_monitoring ? [1] : []

    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  dynamic "monitor_metrics" {
    for_each = local.enable_monitoring ? [1] : []

    content {
      annotations_allowed = null
      labels_allowed      = null
    }
  }

  # ==============================================================================
  # AZURE KEY VAULT SECRETS PROVIDER
  # ==============================================================================
  dynamic "key_vault_secrets_provider" {
    for_each = var.key_vault_secrets_provider_enabled ? [1] : []

    content {
      secret_rotation_enabled  = var.secret_rotation_enabled
      secret_rotation_interval = var.secret_rotation_interval
    }
  }

  # ==============================================================================
  # MICROSOFT DEFENDER FOR CONTAINERS
  # ==============================================================================
  dynamic "microsoft_defender" {
    for_each = var.enable_defender ? [1] : []

    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  # ==============================================================================
  # AUTO-SCALER PROFILE
  # ==============================================================================
  dynamic "auto_scaler_profile" {
    for_each = local.auto_scaler_enabled ? [1] : []

    content {
      balance_similar_node_groups      = var.auto_scaler_profile.balance_similar_node_groups
      expander                         = var.auto_scaler_profile.expander
      max_graceful_termination_sec     = var.auto_scaler_profile.max_graceful_termination_sec
      max_node_provisioning_time       = var.auto_scaler_profile.max_node_provisioning_time
      max_unready_nodes                = var.auto_scaler_profile.max_unready_nodes
      max_unready_percentage           = var.auto_scaler_profile.max_unready_percentage
      new_pod_scale_up_delay           = var.auto_scaler_profile.new_pod_scale_up_delay
      scale_down_delay_after_add       = var.auto_scaler_profile.scale_down_delay_after_add
      scale_down_delay_after_delete    = var.auto_scaler_profile.scale_down_delay_after_delete
      scale_down_delay_after_failure   = var.auto_scaler_profile.scale_down_delay_after_failure
      scan_interval                    = var.auto_scaler_profile.scan_interval
      scale_down_unneeded              = var.auto_scaler_profile.scale_down_unneeded
      scale_down_unready               = var.auto_scaler_profile.scale_down_unready
      scale_down_utilization_threshold = var.auto_scaler_profile.scale_down_utilization_threshold
      skip_nodes_with_local_storage    = var.auto_scaler_profile.skip_nodes_with_local_storage
      skip_nodes_with_system_pods      = var.auto_scaler_profile.skip_nodes_with_system_pods
    }
  }

  # ==============================================================================
  # MAINTENANCE WINDOW
  # ==============================================================================
  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []

    content {
      dynamic "allowed" {
        for_each = maintenance_window.value.allowed

        content {
          day   = allowed.value.day
          hours = allowed.value.hours
        }
      }

      dynamic "not_allowed" {
        for_each = maintenance_window.value.not_allowed

        content {
          start = not_allowed.value.start
          end   = not_allowed.value.end
        }
      }
    }
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      tags["deployment-date"],
      default_node_pool[0].node_count
    ]
  }
}

# ==============================================================================
# ADDITIONAL USER NODE POOLS
# ==============================================================================

resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.additional_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = each.value.vm_size
  node_count            = each.value.enable_auto_scaling ? null : each.value.node_count
  min_count             = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count             = each.value.enable_auto_scaling ? each.value.max_count : null
  enable_auto_scaling   = each.value.enable_auto_scaling
  zones                 = each.value.availability_zones
  max_pods              = each.value.max_pods
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_disk_type          = each.value.os_disk_type
  vnet_subnet_id        = var.vnet_subnet_id
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints
  mode                  = each.value.mode

  upgrade_settings {
    max_surge = "33%"
  }

  tags = merge(
    local.common_tags,
    {
      "nodepool-name" = each.key
      "nodepool-mode" = each.value.mode
    }
  )

  lifecycle {
    ignore_changes = [
      node_count,
      tags["deployment-date"]
    ]
  }
}

# ==============================================================================
# ROLE ASSIGNMENTS FOR MANAGED IDENTITY
# ==============================================================================

# Network Contributor role for the AKS cluster to manage networking resources
resource "azurerm_role_assignment" "network_contributor" {
  scope                = var.vnet_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

# ==============================================================================
# DIAGNOSTIC SETTINGS
# ==============================================================================

resource "azurerm_monitor_diagnostic_setting" "aks" {
  count = local.enable_monitoring ? 1 : 0

  name                       = "${var.cluster_name}-diagnostics"
  target_resource_id         = azurerm_kubernetes_cluster.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Control Plane Logs
  enabled_log {
    category = "kube-apiserver"

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  enabled_log {
    category = "kube-controller-manager"

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  enabled_log {
    category = "kube-scheduler"

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  enabled_log {
    category = "kube-audit"

    retention_policy {
      enabled = true
      days    = 90
    }
  }

  enabled_log {
    category = "kube-audit-admin"

    retention_policy {
      enabled = true
      days    = 90
    }
  }

  enabled_log {
    category = "cluster-autoscaler"

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  # Metrics
  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }
}
