import os
from agents.base_agent import BaseAgent

class ScribeAgent(BaseAgent):
    def __init__(self, cfg):
        super().__init__("Scribe", cfg)

    def write_documentation(self, blueprint: str):
        self.log("Generating module documentation...")
        docs = self.think(f"Write README.md for: {blueprint}")
        
        with open(os.path.join(self.cfg.paths.output_dir, "README.md"), "w") as f:
            f.write(docs)
            
        self.log("Documentation generated.")
