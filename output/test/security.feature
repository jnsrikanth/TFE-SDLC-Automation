
Feature: Ensure AKS Cluster Security

    Scenario: Ensure RBAC is enabled
        Given I have resource that supports tags defined
        When it contains tags
        Then it must contain rbac_enabled
        And its value must be true
