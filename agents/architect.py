from agents.base_agent import BaseAgent

class ArchitectAgent(BaseAgent):
    def __init__(self, cfg):
        super().__init__("Architect", cfg)

    def design_module(self, requirements: str) -> str:
        self.log(f"Analyzing requirements: {requirements}")
        blueprint = self.think(f"Design a Terraform module for: {requirements}")
        self.log("Blueprint created.")
        return blueprint
