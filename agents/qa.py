import os
from agents.base_agent import BaseAgent

class QAAgent(BaseAgent):
    def __init__(self, cfg):
        super().__init__("QA", cfg)

    def generate_bdd_tests(self, blueprint: str):
        self.log("Generating BDD (terraform-compliance) features...")
        feature_code = self.think(self.cfg.prompts.qa.tasks.bdd.format(blueprint=blueprint))
        feature_code = self._clean_content(feature_code)
        
        test_dir = os.path.join(self.cfg.paths.output_dir, "test")
        os.makedirs(test_dir, exist_ok=True)
        
        feature_path = os.path.join(test_dir, "security.feature")
        with open(feature_path, "w") as f:
            f.write(feature_code)
        self.log("BDD features generated.")
        
        # Execute BDD Tests
        self.log("Executing BDD tests with terraform-compliance...")
        try:
            import subprocess
            
            # 1. Terraform Init
            self.log("Running terraform init...")
            subprocess.run(["terraform", "init"], cwd=self.cfg.paths.output_dir, check=True, capture_output=True)
            
            # 2. Terraform Plan
            self.log("Running terraform plan...")
            plan_path = "plan.tfplan"
            # Use -input=false. terraform.tfvars is automatically loaded if present.
            subprocess.run(["terraform", "plan", "-out", plan_path, "-input=false"], cwd=self.cfg.paths.output_dir, check=True, capture_output=True)
            
            # 3. Terraform Compliance
            self.log("Running terraform-compliance...")
            cmd = ["terraform-compliance", "-f", "test", "-p", plan_path]
            result = subprocess.run(cmd, cwd=self.cfg.paths.output_dir, capture_output=True, text=True)
            
            if result.returncode == 0:
                self.log("BDD Tests PASSED")
            else:
                self.log(f"BDD Tests FAILED:\n{result.stdout}\n{result.stderr}")
                
        except Exception as e:
            self.log(f"Error executing BDD tests: {e}")

    def generate_integration_tests(self, blueprint: str):
        self.log("Generating Terratest (Go) code...")
        test_code = self.think(self.cfg.prompts.qa.tasks.integration.format(blueprint=blueprint))
        test_code = self._clean_content(test_code)
        
        test_dir = os.path.join(self.cfg.paths.output_dir, "test")
        os.makedirs(test_dir, exist_ok=True)
        
        test_path = os.path.join(test_dir, "module_test.go")
        with open(test_path, "w") as f:
            f.write(test_code)
            
        self.log("Integration tests generated.")
        
        # Execute Integration Tests
        self.log("Executing Integration tests with Go...")
        try:
            import subprocess
            
            # Initialize Go module if needed
            if not os.path.exists(os.path.join(test_dir, "go.mod")):
                subprocess.run(["go", "mod", "init", "module_test"], cwd=test_dir, capture_output=True)
                subprocess.run(["go", "mod", "tidy"], cwd=test_dir, capture_output=True)

            # Run Go Test
            # Timeout set to avoid hanging forever if infrastructure provisioning takes too long
            cmd = ["go", "test", "-v", "-timeout", "30m"]
            result = subprocess.run(cmd, cwd=test_dir, capture_output=True, text=True)
            
            if result.returncode == 0:
                self.log("Integration Tests PASSED")
            else:
                self.log(f"Integration Tests FAILED:\n{result.stdout}\n{result.stderr}")
                
        except Exception as e:
            self.log(f"Error executing Integration tests: {e}")

    def _clean_content(self, content: str) -> str:
        import re
        # Try to find content within code blocks
        matches = re.findall(r"```(?:\w+)?\n(.*?)```", content, re.DOTALL)
        if matches:
            # Prefer block containing Go package or Feature keyword
            for match in matches:
                if "package " in match or "Feature:" in match:
                    return match.strip()
            # Fallback to longest
            return max(matches, key=len).strip()
        # Fallback: return content as is
        return content.strip()
