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

## Business Value & Efficiency

Implementing this Level 4 Autonomous Agent system transforms the Terraform SDLC from a manual, linear process into a high-velocity, parallelized workflow.

### Key Benefits
1.  **Reduced Development Timelines (50-70% Faster)**:
    *   **Parallel Execution**: While the *Coder* writes HCL, the *QA* agent generates test cases and the *Scribe* drafts documentation simultaneously.
    *   **Instant Feedback**: The *SecOps* agent provides immediate compliance feedback, eliminating the "commit-wait-fail" loop of CI/CD pipelines.

2.  **Enhanced Quality & Consistency**:
    *   **Standardization**: Agents enforce "Golden Copy" standards rigorously across every module, preventing configuration drift.
    *   **Comprehensive Testing**: The *QA* agent automatically generates BDD scenarios (Terratest) that humans often skip due to time pressure.

3.  **Operational Efficiency**:
    *   **Self-Healing**: The agents can iteratively fix issues. If *SecOps* detects a violation, it can instruct *Coder* to apply a fix automatically before human review.
    *   **Documentation Debt**: The *Scribe* agent ensures documentation is never stale, automatically updating `README.md` whenever the code changes.

### AI Engine: Gemini 3.0 Pro
This system is powered by **Google's Gemini 3.0 Pro**, chosen for its superior reasoning capabilities in code generation and infrastructure logic. Its large context window allows it to ingest entire module dependencies and enterprise policy documents to make context-aware decisions.

## Why Level 4 Autonomy?

We classify this system as **Level 4 (High Autonomy)** based on the standard agentic maturity model:

*   **Level 1 (Scripting)**: Simple automation of repetitive tasks (e.g., a bash script to run `terraform apply`).
*   **Level 2 (Copilot)**: AI assists a human who remains the driver (e.g., GitHub Copilot suggesting code snippets).
*   **Level 3 (Conditional Autonomy)**: Agents can perform tasks but require frequent human intervention for decision-making and error handling.
*   **Level 4 (High Autonomy)**: **This System**. The agents operate in a **Goal-Oriented** mode.
    *   **Strategic Planning**: You provide a high-level intent ("Build an AKS cluster"), and the *Architect* agent autonomously decomposes this into technical specifications.
    *   **Self-Correction Loop**: If the *SecOps* agent detects a vulnerability, it can autonomously reject the build and instruct the *Coder* agent to remediate it *without* human intervention.
    *   **Multi-Agent Collaboration**: The agents coordinate their own handoffs (Architect -> Coder -> QA) based on the workflow state, not hard-coded linear scripts.
    *   **Human-on-the-Loop**: Humans are only required for the final review of the "Golden Copy" before publishing, rather than being involved in every step of the drafting process.

## Testing & Security Strategy

This agent distinguishes between different types of validation to ensure a robust module:

### 1. Security & Secrets (SecOps Agent)
*   **Secret Scanning**: Before any code is committed, the SecOps agent runs tools like `detect-secrets` or `gitleaks` to ensure no hardcoded passwords, tokens, or keys exist in the HCL.
*   **Static Analysis (SAST)**: Uses `checkov` or `tfsec` to find infrastructure misconfigurations (e.g., public buckets, unencrypted databases) *without* deploying resources.

### 2. Policy as Code (SecOps Agent)
*   **Tool**: `Sentinel` (HashiCorp) or `OPA` (Open Policy Agent).
*   **Purpose**: Enforces governance rules that are specific to the organization.
*   **Configuration**:
    *   Point the agent to your local policy repository in `conf/config.yaml`:
        ```yaml
        paths:
          policy_library: "/path/to/your/sentinel/policies"
        ```
    *   The agent will simulate running `sentinel apply -config=/path/to/policies` against the generated code.

### 3. Behavior Driven Development (QA Agent)
*   **Tool**: `terraform-compliance` (or similar BDD frameworks).
*   **Purpose**: Validates the *structure* and *policy* of the code using Gherkin syntax (e.g., "GIVEN a resource, WHEN it is an AKS cluster, THEN it must have RBAC enabled"). This is a "Compliance as Code" check.

### 3. Integration Testing (QA Agent)
*   **Tool**: `terratest` (Go).
*   **Purpose**: Validates the *functionality* by actually deploying the resource to a sandbox, running assertions (e.g., making an HTTP request to the cluster), and then destroying it.

## Prompt Engineering & Validation (2025 Standards)

### Prompt as Configuration (Hydra)
We utilize **Hydra** to manage prompts as configuration (`conf/prompts.yaml`), decoupling the "intelligence" from the "logic". This allows for:
*   **Prompt Optimization**: You can A/B test different system instructions or few-shot examples without changing a single line of Python code.
*   **Model Swapping**: Different prompts can be targeted at different models (e.g., a more verbose prompt for a smaller model) via Hydra's config groups.

### The "Gold Standard" of Validation
In the era of Generative AI, we adhere to the **Deterministic + LLM-as-a-Judge** pattern:

1.  **Deterministic Validation (The Foundation)**:
    *   Never trust the LLM to validate its own syntax. Always use the compiler/CLI.
    *   *Example*: The Coder agent's output is validated by `terraform validate` and `tflint`. If these fail, the agent must self-correct.

2.  **LLM-as-a-Judge (Semantic Validation)**:
    *   For qualitative checks (e.g., "Is this documentation clear?"), we use a separate, highly capable model (Gemini 3.0 Pro) acting as a "Critic" to score the output against a rubric.
    *   *Self-Correction*: If the Critic gives a low score, the Generator agent is invoked again with the specific feedback.

3.  **Constitutional AI / Guardrails**:
    *   We embed "Constitutions" (e.g., "No hardcoded secrets") into the SecOps agent's system prompt and verify them with deterministic scanners (`detect-secrets`).
