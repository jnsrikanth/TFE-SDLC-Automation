# Architecture Design

## Overview

The Level 4 Agent is designed as a **Multi-Agent System (MAS)** where specialized agents collaborate to produce a high-quality, secure, and tested Terraform module. The intelligence layer is powered by **Gemini 3.0 Pro**, enabling complex reasoning across architectural design, security compliance, and code generation.

## Agents

### 1. Architect Agent
*   **Role**: Technical Lead.
*   **Input**: High-level user requirements.
*   **Output**: Module Blueprint (Variables, Resources, Outputs structure).
*   **Logic**: Analyzes requirements to determine the necessary Azure resources and their relationships.

### 2. Coder Agent
*   **Role**: Senior Developer.
*   **Input**: Module Blueprint.
*   **Output**: Terraform HCL files (`main.tf`, `variables.tf`, `outputs.tf`).
*   **Logic**: Translates the blueprint into syntactically correct HCL, adhering to best practices.

### 3. SecOps Agent
*   **Role**: Security Engineer.
*   **Input**: Generated HCL code.
*   **Output**: Security Compliance Report.
*   **Tools**:
    *   **Static Analysis (SAST)**: `checkov` or `tfsec` to find misconfigurations (e.g., open security groups, unencrypted disks).
    *   **Secret Scanning**: `detect-secrets` or `gitleaks` to ensure no passwords/keys are hardcoded.
    *   **Policy as Code**: `Sentinel` or `OPA` to enforce enterprise governance.
*   **Logic**: Scans the code and blocks the pipeline if critical vulnerabilities or secrets are found.

### 4. QA Agent
*   **Role**: Test Engineer.
*   **Input**: Module Blueprint.
*   **Output**: Test Suites (BDD & Integration).
*   **Tools**:
    *   **Integration Tests**: `terratest` (Go) to spin up real infrastructure and verify it works (e.g., "Can I curl the load balancer?").
    *   **BDD / Compliance**: `terraform-compliance` (Python/Radish) to run behavior-driven tests written in Gherkin (e.g., "GIVEN I have a storage account, WHEN it is created, THEN it must have https_only enabled").
*   **Logic**: Generates both the Gherkin feature files for BDD and the Go code for Terratest.

### 5. Scribe Agent
*   **Role**: Technical Writer.
*   **Input**: Module Blueprint.
*   **Output**: `README.md` for the module.
*   **Logic**: Documents inputs, outputs, and usage examples.

## Workflow

1.  User triggers `main.py` with requirements.
2.  **Orchestrator** initializes the context.
3.  **Architect** creates the design.
4.  **Coder** generates the code.
5.  **SecOps** scans the code and reports findings.
6.  **QA** generates the test suite.
7.  **Scribe** finalizes the documentation.
