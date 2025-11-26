
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
