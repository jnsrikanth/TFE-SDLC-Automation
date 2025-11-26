# Architecture Design

## Overview

The Level 4 Agent is designed as a **Multi-Agent System (MAS)** where specialized agents collaborate to produce a high-quality, secure, and tested Terraform module.

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
*   **Output**: Security Report.
*   **Logic**: Simulates running tools like Checkov and Sentinel. In a real implementation, it would execute these CLIs against the `output/` directory.

### 4. QA Agent
*   **Role**: Test Engineer.
*   **Input**: Module Blueprint.
*   **Output**: Terratest (Go) code.
*   **Logic**: Generates automated tests to verify the module works as expected.

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
