Feature: Enterprise AKS Cluster Security Compliance
  As a Security Operations Engineer
  I want to ensure the AKS cluster meets enterprise security standards
  So that our Kubernetes infrastructure is protected against threats

  Scenario: Network Security Requirements
    Given I have azurerm_kubernetes_cluster defined
    When it has azurerm_kubernetes_cluster
    Then it must contain network_profile
    And it must contain network_policy
    And its network_profile.network_policy must not be null

  Scenario: Private Cluster Configuration
    Given I have azurerm_kubernetes_cluster defined
    When it has private_cluster_enabled
    Then its value must be true

  Scenario: RBAC Must Be Enabled
    Given I have azurerm_kubernetes_cluster defined
    Then it must contain azure_active_directory_role_based_access_control
    And it must have azure_rbac_enabled defined

  Scenario: Local Admin Accounts Should Be Disabled
    Given I have azurerm_kubernetes_cluster defined
    When it has local_account_disabled
    Then its value must be true

  Scenario: Azure Policy Add-on Must Be Enabled
    Given I have azurerm_kubernetes_cluster defined
    When it has azure_policy_enabled
    Then its value must be true

  Scenario: Microsoft Defender Must Be Enabled
    Given I have azurerm_kubernetes_cluster defined
    Then it must contain microsoft_defender

  Scenario: Key Vault Secrets Provider Must Be Enabled
    Given I have azurerm_kubernetes_cluster defined
    Then it must contain key_vault_secrets_provider
    And it must have secret_rotation_enabled defined

  Scenario: HTTP Application Routing Must Be Disabled
    Given I have azurerm_kubernetes_cluster defined
    When it has http_application_routing_enabled
    Then its value must be false

  Scenario: Network Plugin Must Be Azure CNI
    Given I have azurerm_kubernetes_cluster defined
    When it has network_profile
    Then it must have network_plugin
    And its network_profile.network_plugin must be azure

  Scenario: Load Balancer Must Use Standard SKU
    Given I have azurerm_kubernetes_cluster defined
    When it has network_profile
    Then it must have load_balancer_sku
    And its network_profile.load_balancer_sku must be standard

  Scenario: Monitoring Must Be Enabled
    Given I have azurerm_kubernetes_cluster defined
    Then it must contain oms_agent

  Scenario: Automatic Channel Upgrade Must Be Configured
    Given I have azurerm_kubernetes_cluster defined
    When it has automatic_channel_upgrade
    Then its value must be in ["stable", "patch", "rapid", "node-image"]

  Scenario: System Node Pool Must Have Proper Taints
    Given I have azurerm_kubernetes_cluster defined
    When it has default_node_pool
    Then it must have node_taints
    And its default_node_pool.node_taints must contain CriticalAddonsOnly

  Scenario: Auto-scaling Must Be Enabled for System Node Pool
    Given I have azurerm_kubernetes_cluster defined
    When it has default_node_pool
    Then it must have enable_auto_scaling
    And its default_node_pool.enable_auto_scaling must be true

  Scenario: Node Pools Must Use Availability Zones
    Given I have azurerm_kubernetes_cluster defined
    When it has default_node_pool
    Then it must have zones
    And its default_node_pool.zones must not be empty

  Scenario: Diagnostic Settings Must Be Configured
    Given I have azurerm_monitor_diagnostic_setting defined
    Then it must contain enabled_log
    And it must contain metric

  Scenario: Audit Logs Must Be Retained
    Given I have azurerm_monitor_diagnostic_setting defined
    When it has enabled_log
    Then it must have retention_policy
    And its enabled_log.retention_policy.enabled must be true
    And its enabled_log.retention_policy.days must be greater than 30

  Scenario: Network Contributor Role Must Be Assigned
    Given I have azurerm_role_assignment defined
    When it has role_definition_name
    Then its value must be "Network Contributor"
