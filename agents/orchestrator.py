from agents.architect import ArchitectAgent
from agents.coder import CoderAgent
from agents.secops import SecOpsAgent
from agents.qa import QAAgent
from agents.scribe import ScribeAgent
from omegaconf import DictConfig
import os

class OrchestratorAgent:
    def __init__(self, cfg: DictConfig):
        self.cfg = cfg
        self.architect = ArchitectAgent(cfg)
        self.coder = CoderAgent(cfg)
        self.secops = SecOpsAgent(cfg)
        self.qa = QAAgent(cfg)
        self.scribe = ScribeAgent(cfg)

    def run(self, requirements: str):
        print("=== Starting TFE SDLC Automation Agent ===")
        
        # Hydra manages output dir automatically, but we can ensure subdirs
        os.makedirs(self.cfg.paths.output_dir, exist_ok=True)
        
        # Step 1: Architect designs the module
        blueprint = self.architect.design_module(requirements)
        
        # Step 2: Coder implements the module
        self.coder.write_code(blueprint)
        
        # Step 3: SecOps validates the module
        # 3a. Secret Scanning
        secret_report = self.secops.scan_secrets(self.cfg.paths.output_dir)
        print(secret_report)
        with open(os.path.join(self.cfg.paths.output_dir, "secret_scan_report.txt"), "w") as f:
            f.write(secret_report)
        
        # 3b. SAST
        sast_report = self.secops.run_sast(self.cfg.paths.output_dir)
        print(sast_report)
        with open(os.path.join(self.cfg.paths.output_dir, "sast_report.txt"), "w") as f:
            f.write(sast_report)

        # 3c. Policy as Code
        policy_report = self.secops.run_policy_check(self.cfg.paths.output_dir)
        print(policy_report)
        with open(os.path.join(self.cfg.paths.output_dir, "policy_check_report.txt"), "w") as f:
            f.write(policy_report)
        
        # Step 4: QA generates tests
        # 4a. BDD
        self.qa.generate_bdd_tests(blueprint)
        
        # 4b. Integration Tests
        self.qa.generate_integration_tests(blueprint)
        
        # Step 5: Scribe writes documentation
        self.scribe.write_documentation(blueprint)
        
        print("=== Module Development Complete ===")
        print(f"Artifacts available in: {self.cfg.paths.output_dir}")
