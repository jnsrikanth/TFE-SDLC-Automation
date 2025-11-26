# Level 4 Terraform SDLC Automation Agent

This project implements a multi-agent system to automate the lifecycle of Terraform Module development.

## Architecture

The system consists of the following agents:
*   **Orchestrator**: Manages the workflow.
*   **Architect**: Designs the module blueprint.
*   **Coder**: Generates HCL code.
*   **SecOps**: Validates security (Checkov/Sentinel).
*   **QA**: Generates BDD tests (Terratest).
*   **Scribe**: Generates documentation.

## Usage

1.  Install dependencies (Python 3.9+ required):
    ```bash
    # No external dependencies for the demo, but in production:
    # pip install -r requirements.txt
    ```

2.  Run the agent:
    ```bash
    python main.py --requirements "Standard AKS Cluster with Monitoring and RBAC"
    ```

3.  Check the `output/` directory for the generated module.

## Directory Structure

*   `agents/`: Agent implementations.
*   `core/`: Core utilities and configuration.
*   `output/`: Generated artifacts.
*   `templates/`: Base templates.
