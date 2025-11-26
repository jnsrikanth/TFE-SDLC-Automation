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
        self.log(f"Running Policy as Code (Sentinel) on {code_path}...")
        report = self.think(self.cfg.prompts.secops.tasks.policy.format(code_path=code_path))
        self.log("Policy check complete.")
        return report
