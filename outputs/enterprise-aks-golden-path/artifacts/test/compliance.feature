Feature: Enterprise AKS Cluster Compliance Checks
  As a Compliance Officer
  I want to ensure the AKS cluster meets regulatory and organizational standards
  So that we maintain compliance with governance policies

  Scenario: Cluster Must Have Required Tags
    Given I have azurerm_kubernetes_cluster defined
    Then it must contain tags
    And it must have tags.managed-by
    And it must have tags.cluster-name
    And it must have tags.environment-type

  Scenario: Managed Identity Must Be Used
    Given I have azurerm_kubernetes_cluster defined
    When it has identity
    Then it must have type
    And its identity.type must be in ["SystemAssigned", "UserAssigned"]

  Scenario: Kubernetes Version Must Be Supported
    Given I have azurerm_kubernetes_cluster defined
    When it has kubernetes_version
    Then its value must match the "^\d+\.\d+\.\d+$" regex

  Scenario: Node Disk Encryption Must Be Enabled
    Given I have azurerm_kubernetes_cluster defined
    When it has default_node_pool
    Then it must have os_disk_type
    And its default_node_pool.os_disk_type must be Managed

  Scenario: System Node Pool Must Have Adequate Resources
    Given I have azurerm_kubernetes_cluster defined
    When it has default_node_pool
    Then it must have vm_size
    And it must have min_count
    And its default_node_pool.min_count must be greater than 2

  Scenario: Auto-scaler Profile Must Be Configured for Production
    Given I have azurerm_kubernetes_cluster defined
    When it has auto_scaler_profile
    Then it must have balance_similar_node_groups
    And it must have skip_nodes_with_system_pods
    And its auto_scaler_profile.skip_nodes_with_system_pods must be true

  Scenario: Upgrade Settings Must Limit Surge
    Given I have azurerm_kubernetes_cluster defined
    When it has default_node_pool
    Then it must contain upgrade_settings

  Scenario: Node Pools Must Have Labels
    Given I have azurerm_kubernetes_cluster defined
    When it has default_node_pool
    Then it must have node_labels
    And its default_node_pool.node_labels must not be empty

  Scenario: Additional Node Pools Must Follow Standards
    Given I have azurerm_kubernetes_cluster_node_pool defined
    Then it must contain upgrade_settings
    And it must have tags
    And it must have vnet_subnet_id

  Scenario: DNS Service IP Must Be Within Service CIDR
    Given I have azurerm_kubernetes_cluster defined
    When it has network_profile
    Then it must have service_cidr
    And it must have dns_service_ip

  Scenario: Outbound Type Must Be Properly Configured
    Given I have azurerm_kubernetes_cluster defined
    When it has network_profile
    Then it must have outbound_type
    And its network_profile.outbound_type must be in ["loadBalancer", "userDefinedRouting", "managedNATGateway"]

  Scenario: Secret Rotation Must Be Enabled for Key Vault Provider
    Given I have azurerm_kubernetes_cluster defined
    When it has key_vault_secrets_provider
    Then it must have secret_rotation_enabled
    And its key_vault_secrets_provider.secret_rotation_enabled must be true
    And it must have secret_rotation_interval

  Scenario: Node Resource Group Must Be Specified
    Given I have azurerm_kubernetes_cluster defined
    Then it must have node_resource_group

  Scenario: AAD Integration Must Have Admin Groups
    Given I have azurerm_kubernetes_cluster defined
    When it has azure_active_directory_role_based_access_control
    And it has admin_group_object_ids
    Then its azure_active_directory_role_based_access_control.admin_group_object_ids must not be empty

  Scenario: Metrics Must Be Enabled for Monitoring
    Given I have azurerm_monitor_diagnostic_setting defined
    When it has metric
    Then it must have enabled
    And its metric.enabled must be true

  Scenario: Control Plane Logs Must Be Captured
    Given I have azurerm_monitor_diagnostic_setting defined
    Then it must contain enabled_log
    And its enabled_log.category must contain kube-apiserver
    And its enabled_log.category must contain kube-audit

  Scenario: Container Insights Must Use Log Analytics
    Given I have azurerm_kubernetes_cluster defined
    When it contains oms_agent
    Then it must have log_analytics_workspace_id
