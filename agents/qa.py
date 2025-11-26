import os
from agents.base_agent import BaseAgent

class QAAgent(BaseAgent):
    def __init__(self):
        super().__init__("QA")

    def generate_tests(self, blueprint: str):
        self.log("Generating Terratest code...")
        test_code = self.think(f"Write Terratest code for: {blueprint}")
        
        test_dir = os.path.join(self.config.OUTPUT_DIR, "test")
        os.makedirs(test_dir, exist_ok=True)
        
        with open(os.path.join(test_dir, "module_test.go"), "w") as f:
            f.write(test_code)
            
        self.log("Tests generated.")
