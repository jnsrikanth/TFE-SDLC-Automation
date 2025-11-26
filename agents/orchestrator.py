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
        security_report = self.secops.validate_security(config.OUTPUT_DIR)
        print(security_report)
        
        # Step 4: QA generates tests
        self.qa.generate_tests(blueprint)
        
        # Step 5: Scribe writes documentation
        self.scribe.write_documentation(blueprint)
        
        print("=== Module Development Complete ===")
        print(f"Artifacts available in: {config.OUTPUT_DIR}")
