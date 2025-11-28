from agents.base_agent import BaseAgent

class SecOpsAgent(BaseAgent):
    def __init__(self, cfg):
        super().__init__("SecOps", cfg)

    def scan_secrets(self, code_path: str) -> str:
        self.log(f"Running secret scanning on {code_path}...")
        try:
            # Create a baseline if it doesn't exist (required for detect-secrets)
            import subprocess
            
            # Using detect-secrets scan
            cmd = ["detect-secrets", "scan", code_path]
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode != 0:
                report = f"Secret Scanning Failed:\n{result.stderr}"
            else:
                report = f"Secret Scanning Results:\n{result.stdout}"
                
        except FileNotFoundError:
            report = "detect-secrets tool not found. Please install it."
        except Exception as e:
            report = f"Error running secret scanning: {str(e)}"
            
        self.log("Secret scanning complete.")
        return report

    def run_sast(self, code_path: str) -> str:
        self.log(f"Running SAST (Checkov) on {code_path}...")
        try:
            import subprocess
            # Run checkov on the directory
            cmd = ["checkov", "-d", code_path, "--quiet", "--compact"]
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            # Checkov returns 0 on success, 1 on failure (findings found)
            # We capture stdout regardless
            report = f"Checkov Results:\n{result.stdout}"
            if result.stderr:
                report += f"\nErrors:\n{result.stderr}"
                
        except FileNotFoundError:
            report = "checkov tool not found. Please install it."
        except Exception as e:
            report = f"Error running SAST: {str(e)}"
            
        self.log("SAST complete.")
        return report

    def run_policy_check(self, code_path: str) -> str:
        policy_path = self.cfg.paths.get("policy_library", "policy-library")
        self.log(f"Running Policy as Code (Sentinel) using library at: {policy_path}")
        
        import subprocess
        import os
        import json

        sentinel_bin = os.path.abspath("bin/sentinel")
        if not os.path.exists(sentinel_bin):
            return "Sentinel binary not found at bin/sentinel. Please install it."

        try:
            # 0. Create dummy tfvars to avoid interactive prompts
            tfvars_path = os.path.join(code_path, "terraform.tfvars")
            with open(tfvars_path, "w") as f:
                f.write('project_id = "test-project"\n')
                f.write('location = "US"\n')
                f.write('region = "us-central1"\n')
                f.write('bucket_name = "test-bucket-12345"\n')
                f.write('name = "test-resource"\n')

            # 1. Generate Terraform Plan
            self.log("Generating Terraform plan for Sentinel...")
            subprocess.run(["terraform", "init"], cwd=code_path, check=True, capture_output=True)
            # Use -input=false to prevent hanging
            subprocess.run(["terraform", "plan", "-out=tfplan", "-input=false"], cwd=code_path, check=True, capture_output=True)
            
            # 2. Convert to JSON
            self.log("Converting plan to JSON...")
            plan_json_proc = subprocess.run(
                ["terraform", "show", "-json", "tfplan"], 
                cwd=code_path, 
                check=True, 
                capture_output=True, 
                text=True
            )
            plan_json_path = os.path.join(code_path, "tfplan.json")
            with open(plan_json_path, "w") as f:
                f.write(plan_json_proc.stdout)

            # 3. Run Sentinel Apply
            self.log("Executing Sentinel Apply...")
            
            # We use the -param approach to pass the JSON plan to the policy.
            # The policy must expect a 'tfplan' param.
            
            # Create a simple config file (no mocks needed if we use param)
            config_content = f'''
            policy "gcs-bucket" {{
                source = "{os.path.abspath('policy-library/gcs-bucket.sentinel')}"
                enforcement_level = "advisory"
            }}
            '''
            
            config_path = os.path.join(code_path, "sentinel.hcl")
            with open(config_path, "w") as f:
                f.write(config_content)
                
            # Read the plan JSON
            with open(plan_json_path, "r") as f:
                plan_json_content = f.read()
                
            # Run Sentinel
            # We pass the plan content as a parameter. 
            # Note: This might be large, but for typical modules it's fine.
            cmd = [sentinel_bin, "apply", "-trace", "-config", config_path, "-param", f"tfplan={plan_json_content}"]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            report = f"Sentinel Policy Check Results:\n{result.stdout}"
            if result.stderr:
                report += f"\nStderr:\n{result.stderr}"
                
            if result.returncode != 0:
                report += "\n\nPolicy Check Failed."
            else:
                report += "\n\nPolicy Check Passed."

        except subprocess.CalledProcessError as e:
            report = f"Error running Terraform/Sentinel: {e}\nOutput: {e.output if hasattr(e, 'output') else ''}"
        except Exception as e:
            report = f"Error executing policy check: {str(e)}"
            
        self.log("Policy check complete.")
        return report
