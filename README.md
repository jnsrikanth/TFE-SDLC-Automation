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

## FAQ

### Source of Terraform Code
In this demo, the **Coder Agent** generates code based on internal templates and simulated LLM knowledge. In a production environment, this agent would be enhanced to:
1.  Query the **Terraform Registry** or **Azure/Microsoft Documentation** for the latest resource definitions.
2.  Pull "Golden Copy" modules from an internal service catalog as a base.

### Working with Existing Modules (Brownfield)
The agent is designed to support existing modules that may lack tests or documentation. You can run specific agents to "backfill" these artifacts:

*   **QA Agent**: Can ingest existing `*.tf` files to generate BDD `terratest` cases.
*   **SecOps Agent**: Can scan legacy modules to generate a security compliance report.
*   **Scribe Agent**: Can read existing code to auto-generate `README.md` and `USAGE.md`.

To support this, the `Orchestrator` can be configured to skip the `Architect` and `Coder` phases and point directly to an existing source directory.
