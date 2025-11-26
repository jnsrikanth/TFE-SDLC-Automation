from agents.base_agent import BaseAgent

class SecOpsAgent(BaseAgent):
    def __init__(self):
        super().__init__("SecOps")

    def scan_secrets(self, code_path: str) -> str:
        self.log(f"Running secret scanning on {code_path}...")
        report = self.think(f"Run detect-secrets on {code_path}")
        self.log("Secret scanning complete.")
        return report

    def run_sast(self, code_path: str) -> str:
        self.log(f"Running SAST (Checkov/Sentinel) on {code_path}...")
        report = self.think(f"Run Checkov and Sentinel analysis on {code_path}")
        self.log("SAST complete.")
        return report
