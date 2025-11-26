from agents.base_agent import BaseAgent

class SecOpsAgent(BaseAgent):
    def __init__(self, cfg):
        super().__init__("SecOps", cfg)

    def scan_secrets(self, code_path: str) -> str:
        self.log(f"Running secret scanning on {code_path}...")
        report = self.think(self.cfg.prompts.secops.tasks.secrets.format(code_path=code_path))
        self.log("Secret scanning complete.")
        return report

    def run_sast(self, code_path: str) -> str:
        self.log(f"Running SAST (Checkov) on {code_path}...")
        report = self.think(self.cfg.prompts.secops.tasks.sast.format(code_path=code_path))
        self.log("SAST complete.")
        return report

    def run_policy_check(self, code_path: str) -> str:
        policy_path = self.cfg.paths.get("policy_library", "policy-library")
        self.log(f"Running Policy as Code (Sentinel) using library at: {policy_path}")
        
        # In a real scenario, we would run:
        # subprocess.run(["sentinel", "apply", "-config", policy_path, code_path])
        
        # For this demo, we simulate the agent analyzing the 'output' of that CLI command
        # We pass the policy path to the prompt so the LLM knows what rules to check against contextually
        prompt = self.cfg.prompts.secops.tasks.policy.format(
            code_path=code_path, 
            policy_path=policy_path
        )
        report = self.think(prompt)
        self.log("Policy check complete.")
        return report
