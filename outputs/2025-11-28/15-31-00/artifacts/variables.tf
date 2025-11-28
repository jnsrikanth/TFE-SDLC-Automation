```hcl
# variables.tf for Enterprise AKS Cluster

#------------------------------------------------------------------------------
# Cluster Identification
#------------------------------------------------------------------------------

variable "cluster_name" {
  description = "The name of the Azure Kubernetes Service (AKS) cluster."
  type        = string
  validation {
    condition     = length(var.cluster_name) >= 1 && length(var.cluster_name) <= 63
    error_message = "Cluster name must be between 1 and 63 characters long."
  }
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]$", var.cluster_name))
    error_message = "Cluster name must start and end with a letter or number, and can contain letters, numbers, and hyphens."
  }
  default = "aks-enterprise-cluster"
}

variable "location" {
  description = "The Azure region where the AKS cluster will be deployed."
  type        = string
  validation {
    # This is a simplified list, a more comprehensive validation would involve an external data source or a very long list.
    condition     = contains(["eastus", "eastus2", "westus", "westus2", "westus3", "centralus", "northcentralus", "southcentralus", "westeurope", "northeurope", "uksouth", "ukwest", "eastasia", "southeastasia", "japaneast", "japanwest", "koreacentral", "koreasouth", "australiaeast", "australiasoutheast", "brazilsouth", "canadacentral", "canadaeast", "francecentral", "francesouth", "germanywestcentral", "germanynorth", "norwayeast", "norwaywest", "switzerlandnorth", "switzerlandwest", "uaenorth", "uaesouth", "usgovvirginia", "usgovarizona", "jioindiawest", "jioindiasouth"], var.location)
    error_message = "Invalid Azure region specified. Please provide a valid Azure region."
  }
  default = "eastus"
}

variable "resource_group_name" {
  description = "The name of the Azure Resource Group where the AKS cluster and its associated resources will be created."
  type        = string
  validation {
    condition     = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters long."
  }
  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]{1,90}$", var.resource_group_name))
    error_message = "Resource group name can contain alphanumeric characters, underscores, periods, and hyphens. It cannot end with a period."
  }
  default = "rg-aks-enterprise"
}

variable "tags" {
  description = "A map of tags to assign to the AKS cluster and its associated resources."
  type        = map(string)
  default     = {
    environment = "production"
    managed_by  = "terraform"
    purpose     = "enterprise-aks"
  }
}

#------------------------------------------------------------------------------
# Networking
#------------------------------------------------------------------------------

variable "vnet_name" {
  description = "The name of the Virtual Network (VNet) to use or create for the AKS cluster."
  type        = string
  validation {
    condition     = length(var.vnet_name) >= 1 && length(var.vnet_name) <= 64
    error_message = "VNet name must be between 1 and 64 characters long."
  }
  default = "vnet-aks-enterprise"
}

variable "vnet_address_prefix" {
  description = "The address space for the Virtual Network (VNet) in CIDR notation."
  type        = string
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(\\/([0-9]|[1-2][0-9]|3[0-2]))?$", var.vnet_address_prefix))
    error_message = "VNet address prefix must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }
  default = "10.1.0.0/16"
}

variable "aks_subnet_name" {
  description = "The name of the subnet for the AKS cluster nodes."
  type        = string
  validation {
    condition     = length(var.aks_subnet_name) >= 1 && length(var.aks_subnet_name) <= 80
    error_message = "AKS subnet name must be between 1 and 80 characters long."
  }
  default = "snet-aks"
}

variable "aks_subnet_prefix" {
  description = "The address range for the AKS subnet in CIDR notation."
  type        = string
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(\\/([0-9]|[1-2][0-9]|3[0-2]))?$", var.aks_subnet_prefix))
    error_message = "AKS subnet prefix must be a valid CIDR block (e.g., 10.1.1.0/24)."
  }
  default = "10.1.1.0/24"
}

variable "network_plugin" {
  description = "The network plugin to use for the AKS cluster."
  type        = string
  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "Network plugin must be either 'azure' or 'kubenet'."
  }
  default = "azure" # Azure CNI is recommended for enterprise scenarios
}

variable "network_policy" {
  description = "The network policy to use for the AKS cluster."
  type        = string
  validation {
    condition     = contains(["azure", "calico"], var.network_policy)
    error_message = "Network policy must be either 'azure' or 'calico'."
  }
  default = "azure" # Azure Policy is a good default, Calico offers more advanced features
}

variable "load_balancer_sku" {
  description = "The SKU of the Azure Load Balancer to use for the AKS cluster."
  type        = string
  validation {
    condition     = contains(["standard", "basic"], var.load_balancer_sku)
    error_message = "Load balancer SKU must be either 'standard' or 'basic'."
  }
  default = "standard" # Standard SKU offers more features and higher availability
}

variable "private_cluster_enabled" {
  description = "Specifies whether the AKS cluster should be configured as a private cluster."
  type        = bool
  default     = false # Set to true for enhanced security, but requires careful network configuration.
}

variable "private_dns_zone_id" {
  description = "The resource ID of the private DNS zone to use for the private cluster."
  type        = string
  default     = null # Required if private_cluster_enabled is true.
  validation {
    condition = var.private_cluster_enabled == false || (var.private_cluster_enabled == true && var.private_dns_zone_id != null)
    error_message = "private_dns_zone_id is required when private_cluster_enabled is true."
  }
}

variable "dns_prefix" {
  description = "DNS prefix to use for the Public IP address of the AKS cluster's API server (if not private)."
  type        = string
  validation {
    condition     = length(var.dns_prefix) >= 1 && length(var.dns_prefix) <= 63
    error_message = "DNS prefix must be between 1 and 63 characters long."
  }
  default = "aks-cluster-dns"
}

#------------------------------------------------------------------------------
# Node Pools
#------------------------------------------------------------------------------

variable "default_node_pool_name" {
  description = "The name of the default system node pool."
  type        = string
  validation {
    condition     = length(var.default_node_pool_name) >= 1 && length(var.default_node_pool_name) <= 63
    error_message = "Default node pool name must be between 1 and 63 characters long."
  }
  default = "agentpool"
}

variable "default_node_pool_vm_size" {
  description =