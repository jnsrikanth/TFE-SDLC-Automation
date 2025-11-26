import os
from agents.base_agent import BaseAgent

class QAAgent(BaseAgent):
    def __init__(self, cfg):
        super().__init__("QA", cfg)

    def generate_bdd_tests(self, blueprint: str):
        self.log("Generating BDD (terraform-compliance) features...")
        feature_code = self.think(f"Write terraform-compliance features for: {blueprint}")
        
        test_dir = os.path.join(self.cfg.paths.output_dir, "test")
        os.makedirs(test_dir, exist_ok=True)
        
        with open(os.path.join(test_dir, "security.feature"), "w") as f:
            f.write(feature_code)
        self.log("BDD features generated.")

    def generate_integration_tests(self, blueprint: str):
        self.log("Generating Terratest (Go) code...")
        test_code = self.think(f"Write Terratest code for: {blueprint}")
        
        test_dir = os.path.join(self.cfg.paths.output_dir, "test")
        os.makedirs(test_dir, exist_ok=True)
        
        with open(os.path.join(test_dir, "module_test.go"), "w") as f:
            f.write(test_code)
            
        self.log("Integration tests generated.")
