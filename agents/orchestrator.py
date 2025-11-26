from agents.architect import ArchitectAgent
from agents.coder import CoderAgent
from agents.secops import SecOpsAgent
from agents.qa import QAAgent
from agents.scribe import ScribeAgent
from core.config import config

class OrchestratorAgent:
    def __init__(self):
        self.architect = ArchitectAgent()
        self.coder = CoderAgent()
        self.secops = SecOpsAgent()
        self.qa = QAAgent()
        self.scribe = ScribeAgent()

    def run(self, requirements: str):
        print("=== Starting TFE SDLC Automation Agent ===")
        config.ensure_dirs()
        
        # Step 1: Architect designs the module
        blueprint = self.architect.design_module(requirements)
        
        # Step 2: Coder implements the module
        self.coder.write_code(blueprint)
        
        # Step 3: SecOps validates the module
        # 3a. Secret Scanning
        secret_report = self.secops.scan_secrets(config.OUTPUT_DIR)
        print(secret_report)
        
        # 3b. SAST
        sast_report = self.secops.run_sast(config.OUTPUT_DIR)
        print(sast_report)

        # 3c. Policy as Code
        policy_report = self.secops.run_policy_check(config.OUTPUT_DIR)
        print(policy_report)
        
        # Step 4: QA generates tests
        # 4a. BDD
        self.qa.generate_bdd_tests(blueprint)
        
        # 4b. Integration Tests
        self.qa.generate_integration_tests(blueprint)
        
        # Step 5: Scribe writes documentation
        self.scribe.write_documentation(blueprint)
        
        print("=== Module Development Complete ===")
        print(f"Artifacts available in: {config.OUTPUT_DIR}")
