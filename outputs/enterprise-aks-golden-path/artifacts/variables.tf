# ==============================================================================
# REQUIRED VARIABLES
# ==============================================================================

variable "cluster_name" {
  description = "The name of the AKS cluster"
  type        = string

  validation {
    condition     = length(var.cluster_name) >= 3 && length(var.cluster_name) <= 63
    error_message = "Cluster name must be between 3 and 63 characters."
  }
}

variable "resource_group_name" {
  description = "The name of the resource group where the AKS cluster will be created"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string

  validation {
    condition     = contains(["eastus", "eastus2", "westus2", "westus3", "centralus", "northeurope", "westeurope", "uksouth", "southeastasia", "australiaeast"], var.location)
    error_message = "Location must be a valid Azure region."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = "1.28.3"

  validation {
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+$", var.kubernetes_version))
    error_message = "Kubernetes version must be in format X.Y.Z (e.g., 1.28.3)."
  }
}

# ==============================================================================
# NETWORKING CONFIGURATION
# ==============================================================================

variable "vnet_subnet_id" {
  description = "The ID of the subnet where the AKS cluster nodes will be deployed"
  type        = string
}

variable "network_plugin" {
  description = "Network plugin to use for networking (azure or kubenet)"
  type        = string
  default     = "azure"

  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "Network plugin must be either 'azure' or 'kubenet'."
  }
}

variable "network_policy" {
  description = "Network policy to use (azure, calico, or null)"
  type        = string
  default     = "azure"

  validation {
    condition     = var.network_policy == null || contains(["azure", "calico"], var.network_policy)
    error_message = "Network policy must be either 'azure', 'calico', or null."
  }
}

variable "service_cidr" {
  description = "CIDR range for Kubernetes services"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.service_cidr, 0))
    error_message = "Service CIDR must be a valid CIDR block."
  }
}

variable "dns_service_ip" {
  description = "IP address within the Kubernetes service address range for DNS"
  type        = string
  default     = "10.0.0.10"

  validation {
    condition     = can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", var.dns_service_ip))
    error_message = "DNS service IP must be a valid IPv4 address."
  }
}

variable "docker_bridge_cidr" {
  description = "CIDR notation IP range for Docker bridge"
  type        = string
  default     = "172.17.0.1/16"

  validation {
    condition     = can(cidrhost(var.docker_bridge_cidr, 0))
    error_message = "Docker bridge CIDR must be a valid CIDR block."
  }
}

variable "outbound_type" {
  description = "Outbound routing method (loadBalancer, userDefinedRouting, or managedNATGateway)"
  type        = string
  default     = "loadBalancer"

  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting", "managedNATGateway"], var.outbound_type)
    error_message = "Outbound type must be loadBalancer, userDefinedRouting, or managedNATGateway."
  }
}

# ==============================================================================
# NODE POOL CONFIGURATION
# ==============================================================================

variable "default_node_pool" {
  description = "Configuration for the default system node pool"
  type = object({
    name                = string
    vm_size             = string
    node_count          = number
    min_count           = number
    max_count           = number
    enable_auto_scaling = bool
    availability_zones  = list(string)
    max_pods            = number
    os_disk_size_gb     = number
    os_disk_type        = string
    node_labels         = map(string)
    node_taints         = list(string)
  })

  default = {
    name                = "system"
    vm_size             = "Standard_D4s_v5"
    node_count          = 3
    min_count           = 3
    max_count           = 10
    enable_auto_scaling = true
    availability_zones  = ["1", "2", "3"]
    max_pods            = 110
    os_disk_size_gb     = 128
    os_disk_type        = "Managed"
    node_labels = {
      "nodepool-type" = "system"
      "environment"   = "production"
    }
    node_taints = ["CriticalAddonsOnly=true:NoSchedule"]
  }
}

variable "additional_node_pools" {
  description = "Additional user node pools to create"
  type = map(object({
    vm_size             = string
    node_count          = number
    min_count           = number
    max_count           = number
    enable_auto_scaling = bool
    availability_zones  = list(string)
    max_pods            = number
    os_disk_size_gb     = number
    os_disk_type        = string
    node_labels         = map(string)
    node_taints         = list(string)
    mode                = string
  }))

  default = {}
}

# ==============================================================================
# IDENTITY & RBAC
# ==============================================================================

variable "identity_type" {
  description = "Type of identity used for the AKS cluster (SystemAssigned or UserAssigned)"
  type        = string
  default     = "SystemAssigned"

  validation {
    condition     = contains(["SystemAssigned", "UserAssigned"], var.identity_type)
    error_message = "Identity type must be either SystemAssigned or UserAssigned."
  }
}

variable "user_assigned_identity_id" {
  description = "ID of user-assigned managed identity (required if identity_type is UserAssigned)"
  type        = string
  default     = null
}

variable "enable_azure_rbac" {
  description = "Enable Azure RBAC for Kubernetes authorization"
  type        = bool
  default     = true
}

variable "azure_rbac_managed" {
  description = "Enable Azure AD integration with managed Azure RBAC"
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "List of Azure AD group object IDs that will have admin access to the cluster"
  type        = list(string)
  default     = []
}

variable "local_account_disabled" {
  description = "If true, local accounts will be disabled (requires AAD integration)"
  type        = bool
  default     = true
}

# ==============================================================================
# MONITORING & OBSERVABILITY
# ==============================================================================

variable "enable_container_insights" {
  description = "Enable Azure Monitor Container Insights"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for Container Insights"
  type        = string
  default     = null
}

variable "oms_agent_enabled" {
  description = "Enable the OMS agent for monitoring"
  type        = bool
  default     = true
}

# ==============================================================================
# SECURITY & COMPLIANCE
# ==============================================================================

variable "enable_private_cluster" {
  description = "Enable private cluster (API server accessible only via private network)"
  type        = bool
  default     = false
}

variable "private_dns_zone_id" {
  description = "ID of private DNS zone for private cluster (system or custom zone ID)"
  type        = string
  default     = "System"
}

variable "enable_pod_security_policy" {
  description = "Enable Kubernetes Pod Security Policy (deprecated in K8s 1.25+)"
  type        = bool
  default     = false
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy Add-on for AKS"
  type        = bool
  default     = true
}

variable "enable_defender" {
  description = "Enable Microsoft Defender for Containers"
  type        = bool
  default     = true
}

variable "http_application_routing_enabled" {
  description = "Enable HTTP Application Routing (not recommended for production)"
  type        = bool
  default     = false
}

variable "key_vault_secrets_provider_enabled" {
  description = "Enable Azure Key Vault Secrets Provider for AKS"
  type        = bool
  default     = true
}

variable "secret_rotation_enabled" {
  description = "Enable secret rotation for Key Vault Secrets Provider"
  type        = bool
  default     = true
}

variable "secret_rotation_interval" {
  description = "Rotation poll interval for Key Vault secrets"
  type        = string
  default     = "2m"
}

# ==============================================================================
# AUTO-SCALING
# ==============================================================================

variable "enable_auto_scaling" {
  description = "Enable cluster autoscaler"
  type        = bool
  default     = true
}

variable "auto_scaler_profile" {
  description = "Configuration for the cluster autoscaler"
  type = object({
    balance_similar_node_groups      = bool
    expander                         = string
    max_graceful_termination_sec     = number
    max_node_provisioning_time       = string
    max_unready_nodes                = number
    max_unready_percentage           = number
    new_pod_scale_up_delay           = string
    scale_down_delay_after_add       = string
    scale_down_delay_after_delete    = string
    scale_down_delay_after_failure   = string
    scan_interval                    = string
    scale_down_unneeded              = string
    scale_down_unready               = string
    scale_down_utilization_threshold = number
    skip_nodes_with_local_storage    = bool
    skip_nodes_with_system_pods      = bool
  })

  default = {
    balance_similar_node_groups      = true
    expander                         = "random"
    max_graceful_termination_sec     = 600
    max_node_provisioning_time       = "15m"
    max_unready_nodes                = 3
    max_unready_percentage           = 45
    new_pod_scale_up_delay           = "10s"
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_delete    = "10s"
    scale_down_delay_after_failure   = "3m"
    scan_interval                    = "10s"
    scale_down_unneeded              = "10m"
    scale_down_unready               = "20m"
    scale_down_utilization_threshold = 0.5
    skip_nodes_with_local_storage    = true
    skip_nodes_with_system_pods      = true
  }
}

# ==============================================================================
# MAINTENANCE & UPGRADE
# ==============================================================================

variable "automatic_channel_upgrade" {
  description = "The upgrade channel for the cluster (patch, rapid, node-image, stable, or none)"
  type        = string
  default     = "stable"

  validation {
    condition     = contains(["patch", "rapid", "node-image", "stable", "none"], var.automatic_channel_upgrade)
    error_message = "Automatic channel upgrade must be patch, rapid, node-image, stable, or none."
  }
}

variable "maintenance_window" {
  description = "Maintenance window configuration for AKS"
  type = object({
    allowed = list(object({
      day   = string
      hours = list(number)
    }))
    not_allowed = list(object({
      start = string
      end   = string
    }))
  })
  default = null
}

# ==============================================================================
# TAGS & METADATA
# ==============================================================================

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "node_resource_group_name" {
  description = "Name of the resource group for AKS-managed resources (auto-generated if not specified)"
  type        = string
  default     = null
}
