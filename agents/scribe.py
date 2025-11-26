import os
from agents.base_agent import BaseAgent

class ScribeAgent(BaseAgent):
    def __init__(self):
        super().__init__("Scribe")

    def write_documentation(self, blueprint: str):
        self.log("Generating module documentation...")
        docs = self.think(f"Write README.md for: {blueprint}")
        
        with open(os.path.join(self.config.OUTPUT_DIR, "README.md"), "w") as f:
            f.write(docs)
            
        self.log("Documentation generated.")
