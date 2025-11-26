from agents.base_agent import BaseAgent

class SecOpsAgent(BaseAgent):
    def __init__(self):
        super().__init__("SecOps")

    def validate_security(self, code_path: str) -> str:
        self.log(f"Running security scans on {code_path}...")
        report = self.think(f"Run Checkov and Sentinel analysis on {code_path}")
        self.log("Security scan complete.")
        return report
