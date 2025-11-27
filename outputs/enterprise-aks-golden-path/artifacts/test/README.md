# Testing Guide - Enterprise AKS Module

This guide covers all testing approaches for the AKS Terraform module.

## 🧪 Test Types

### 1. Static Analysis Tests
- **Terraform Validation**: Syntax and configuration validation
- **TFLint**: Linting and best practices
- **Checkov**: Security and compliance scanning

### 2. BDD Tests (terraform-compliance)
- **Security Compliance**: `security.feature`
- **Organizational Policies**: `compliance.feature`

### 3. Integration Tests (Terratest)
- **Full deployment validation**
- **Connectivity tests**
- **Feature verification**

## 🚀 Running Tests

### Prerequisites

```bash
# Install Terraform
brew install terraform

# Install TFLint
brew install tflint

# Install Checkov (Python)
pip install checkov

# Install terraform-compliance (Python)
pip install terraform-compliance

# Install Go (for Terratest)
brew install go

# Navigate to test directory
cd test
go mod download
```

### Static Analysis

#### Terraform Validate
```bash
cd ..  # Module root
terraform init
terraform validate
terraform fmt -check -recursive
```

Expected output:
```
Success! The configuration is valid.
```

#### TFLint
```bash
cd ..  # Module root
tflint --init
tflint --recursive
```

Expected: No errors or warnings

#### Checkov Security Scan
```bash
cd ..  # Module root
checkov -d . --framework terraform --output cli

# For JSON output
checkov -d . --framework terraform --output json > security/checkov-results.json
```

Expected: All checks passed

### BDD Tests

#### Run All BDD Features
```bash
# Generate plan
cd ..
terraform init
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# Run terraform-compliance
terraform-compliance -f test/ -p tfplan.json
```

#### Run Specific Feature
```bash
# Security tests only
terraform-compliance -f test/security.feature -p tfplan.json

# Compliance tests only
terraform-compliance -f test/compliance.feature -p tfplan.json
```

Expected output:
```
✓ All tests passed
19 scenarios (19 passed)
```

### Integration Tests (Terratest)

#### Setup Azure Authentication
```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Create service principal (if needed)
az ad sp create-for-rbac --name "terratest-sp" --role Contributor
```

#### Set Environment Variables
```bash
export ARM_CLIENT_ID="<service_principal_app_id>"
export ARM_CLIENT_SECRET="<service_principal_password>"
export ARM_SUBSCRIPTION_ID="<subscription_id>"
export ARM_TENANT_ID="<tenant_id>"
export TF_VAR_admin_group_object_ids='["<your_aad_group_id>"]'
```

#### Run Tests

```bash
cd test

# Run all tests (WARNING: Creates real Azure resources)
go test -v -timeout 90m

# Run specific test
go test -v -timeout 90m -run TestEnterpriseAKSClusterDeployment

# Run tests in parallel
go test -v -timeout 90m -parallel 2
```

#### Test Configuration

Create `testfixtures/terraform.tfvars`:
```hcl
cluster_name        = "aks-terratest-001"
resource_group_name = "rg-terratest-aks"
location            = "eastus"
kubernetes_version  = "1.28.3"

# Pre-created network resources
vnet_subnet_id             = "/subscriptions/.../subnets/subnet-aks-test"
log_analytics_workspace_id = "/subscriptions/.../workspaces/law-test"

# AAD Group for admin access
admin_group_object_ids = ["xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"]

tags = {
  environment = "testing"
  purpose     = "terratest"
  auto-delete = "true"
}
```

## 📊 Test Coverage

### Security Tests Coverage

| Test Area | Coverage | Test Type |
|-----------|----------|-----------|
| Network Security | 100% | BDD + Checkov |
| RBAC Configuration | 100% | BDD + Integration |
| Monitoring | 100% | BDD + Integration |
| Secret Management | 100% | BDD + Detect-Secrets |
| Policy Enforcement | 100% | BDD + Sentinel |
| Azure Defender | 100% | BDD + Integration |

### Integration Tests Coverage

| Component | Test Function | Status |
|-----------|---------------|--------|
| Cluster Deployment | `testClusterBasicProperties` | ✅ |
| Networking | `testNetworkingConfiguration` | ✅ |
| RBAC & Identity | `testRBACConfiguration` | ✅ |
| Monitoring | `testMonitoringConfiguration` | ✅ |
| Security Features | `testSecurityFeatures` | ✅ |
| Node Pools | `testNodePoolConfiguration` | ✅ |
| K8s Connectivity | `testKubernetesConnectivity` | ✅ |

## 🐛 Troubleshooting

### Common Issues

#### Terratest Timeout
```bash
# Increase timeout
go test -v -timeout 120m
```

#### Azure Quota Limits
```bash
# Check current quotas
az vm list-usage --location eastus --output table

# Request quota increase if needed
```

#### Authentication Errors
```bash
# Verify Azure login
az account show

# Re-authenticate
az login --use-device-code
```

#### Test Resource Cleanup
```bash
# If tests fail, manually clean up
az group delete --name rg-terratest-aks --yes --no-wait
```

### Test Debugging

#### Enable Terratest Logging
```bash
# Set log level
export TF_LOG=DEBUG
export TERRATEST_LOG_LEVEL=debug

go test -v
```

#### Save Test Outputs
```bash
# Keep resources for inspection
go test -v -timeout 90m -run TestEnterpriseAKSClusterDeployment 2>&1 | tee test-output.log
```

## 📋 CI/CD Integration

### GitHub Actions Example

```yaml
name: Terraform Tests

on: [push, pull_request]

jobs:
  static-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - name: Terraform Validate
        run: |
          terraform init
          terraform validate
      - name: Run Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: .
          framework: terraform

  bdd-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install terraform-compliance
        run: pip install terraform-compliance
      - name: Run BDD Tests
        run: |
          terraform init
          terraform plan -out=tfplan.binary
          terraform show -json tfplan.binary > tfplan.json
          terraform-compliance -f test/ -p tfplan.json

  integration-tests:
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      - name: Run Terratest
        env:
          ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
          ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
          ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
          ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
        run: |
          cd test
          go mod download
          go test -v -timeout 90m
```

## 📈 Test Metrics

Track these metrics in your CI/CD:
- **Test Pass Rate**: Target 100%
- **Security Scan Pass Rate**: Target 100%
- **Code Coverage**: Measured via Terratest
- **Test Execution Time**: Monitor for performance
- **Cost of Test Runs**: Track Azure resource costs

## 🔄 Continuous Testing

### Pre-commit Hooks

```bash
# .git/hooks/pre-commit
#!/bin/bash
terraform fmt -check -recursive
tflint
checkov -d . --quiet
```

### Scheduled Testing

Run full integration tests:
- **Nightly**: Against develop branch
- **Weekly**: Against main branch with latest K8s version
- **On-demand**: For releases and hotfixes

---

**Note**: Integration tests create real Azure resources and incur costs. Use dedicated test subscriptions with cost alerts configured.
