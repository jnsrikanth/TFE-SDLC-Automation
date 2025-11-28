```hcl
# variables.tf

#------------------------------------------------------------------------------
# Cluster Identification
#------------------------------------------------------------------------------

variable "cluster_name" {
  description = "The name of the Azure Kubernetes Service (AKS) cluster."
  type        = string
  default     = "enterprise-aks-cluster"

  validation {
    condition     = length(var.cluster_name) >= 1 && length(var.cluster_name) <= 63
    error_message = "The cluster name must be between 1 and 63 characters long."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]*$", var.cluster_name))
    error_message = "The cluster name can only contain alphanumeric characters and hyphens."
  }
}

variable "location" {
  description = "The Azure region where the AKS cluster will be deployed."
  type        = string
  default     = "East US"

  validation {
    condition     = length(var.location) > 0
    error_message = "The location cannot be empty."
  }
}

variable "resource_group_name" {
  description = "The name of the Azure Resource Group where the AKS cluster will be deployed."
  type        = string
  default     = "enterprise-aks-rg"

  validation {
    condition     = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90
    error_message = "The resource group name must be between 1 and 90 characters long."
  }
}

#------------------------------------------------------------------------------
# Networking
#------------------------------------------------------------------------------

variable "vnet_name" {
  description = "The name of the Azure Virtual Network for the AKS cluster."
  type        = string
  default     = "enterprise-aks-vnet"

  validation {
    condition     = length(var.vnet_name) >= 1 && length(var.vnet_name) <= 64
    error_message = "The VNet name must be between 1 and 64 characters long."
  }
}

variable "vnet_address_prefix" {
  description = "The address prefix for the Azure Virtual Network in CIDR notation."
  type        = string
  default     = "10.0.0.0/8"

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$", var.vnet_address_prefix))
    error_message = "The VNet address prefix must be a valid CIDR block (e.g., 10.0.0.0/8)."
  }
}

variable "aks_subnet_name" {
  description = "The name of the subnet for the AKS cluster."
  type        = string
  default     = "aks-subnet"

  validation {
    condition     = length(var.aks_subnet_name) >= 1 && length(var.aks_subnet_name) <= 80
    error_message = "The AKS subnet name must be between 1 and 80 characters long."
  }
}

variable "aks_subnet_prefix" {
  description = "The address prefix for the AKS subnet in CIDR notation."
  type        = string
  default     = "10.240.0.0/16"

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$", var.aks_subnet_prefix))
    error_message = "The AKS subnet prefix must be a valid CIDR block (e.g., 10.240.0.0/16)."
  }
}

variable "private_dns_zone_name" {
  description = "The name of the private DNS zone for AKS cluster."
  type        = string
  default     = "privatelink.azurecr.io" # Common default, adjust if needed
}

variable "network_plugin" {
  description = "The network plugin to use for the AKS cluster. Options: azure, kubenet."
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "Invalid network plugin. Must be 'azure' or 'kubenet'."
  }
}

variable "network_policy" {
  description = "The network policy to use for the AKS cluster. Options: azure, calico."
  type        = string
  default     = "azure"
  validation {
    condition     = contains(["azure", "calico"], var.network_policy)
    error_message = "Invalid network policy. Must be 'azure' or 'calico'."
  }
}

variable "enable_private_cluster" {
  description = "Specifies whether the AKS cluster should be a private cluster."
  type        = bool
  default     = false
}

variable "private_dns_zone_id" {
  description = "The resource ID of the private DNS zone to use for the private cluster. Required if enable_private_cluster is true."
  type        = string
  default     = null
}

variable "load_balancer_sku" {
  description = "The SKU of the Load Balancer to use for the AKS cluster. Options: basic, standard."
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["basic", "standard"], var.load_balancer_sku)
    error_message = "Invalid load balancer SKU. Must be 'basic' or 'standard'."
  }
}

#------------------------------------------------------------------------------
# Node Pools
#------------------------------------------------------------------------------

variable "system_node_pool" {
  description = "Configuration for the system node pool."
  type = object({
    name                  = string
    vm_size               = string
    node_count            = number
    os_disk_size_gb       = number
    enable_auto_scaling   = bool
    min_count             = number
    max_count             = number
    zones                 = list(string)
    enable_node_public_ip = bool
    tags                  = map(string)
  })
  default = {
    name                  = "systempool"
    vm_size               = "Standard_DS2_v2"
    node_count            = 3
    os_disk_size_gb       = 128
    enable_auto_scaling   = true
    min_count             = 1
    max_count             = 5
    zones                 = ["1", "2", "3"]
    enable_node_public_ip = false
    tags                  = {
      "nodepool-type" = "system"
    }
  }

  validation {
    # Basic validation for object properties
    condition = length(var.system_node_pool.name) > 0 &&
      length(var.system_node_pool.vm_size) > 0 &&
      var.system_node_pool.node_count > 0 &&
      var.system_node_pool.os_disk_size_gb > 0 &&
      var.system_node_pool.min_count >= 0 &&
      var.system_node_pool.max_count >= var.system_node_pool.min_count
    error_message = "System node pool configuration is invalid. Check name, VM size, node count, disk size, and auto-scaling min/max counts."
  }
}

variable "user_node_pools" {
  description = "List of configurations for user node pools. Each element is an object."
  type = list(object({
    name                  = string
    vm_size               = string
    node_count            = number
    os_disk_size_gb       = number
    enable_auto_scaling   = bool
    min_count             = number
    max_count             = number
    zones                 = list(string)
    enable_node_public_ip = bool
    tags                  = map(string)
  }))
  default = [
    {
      name                  = "userpool1"
      vm_size               = "Standard_DS2_v2"
      node_count            = 1
      os_disk_size_gb       = 128
      enable_auto_scaling   = true
      min_count             = 1
      max_count             = 10
      zones                 = ["1", "2", "3"]
      enable_node_public_ip = false
      tags                  = {
        "nod