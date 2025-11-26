import os
from agents.base_agent import BaseAgent

class CoderAgent(BaseAgent):
    def __init__(self, cfg):
        super().__init__("Coder", cfg)

    def write_code(self, blueprint: str):
        self.log("Generating Terraform code based on blueprint...")
        
        # Generate main.tf
        main_tf = self.think(self.cfg.prompts.coder.tasks.main.format(blueprint=blueprint))
        self._write_file("main.tf", main_tf)
        
        # Generate variables.tf
        vars_tf = self.think(self.cfg.prompts.coder.tasks.variables.format(blueprint=blueprint))
        self._write_file("variables.tf", vars_tf)
        
        # Generate outputs.tf
        outputs_tf = self.think(self.cfg.prompts.coder.tasks.outputs.format(blueprint=blueprint))
        self._write_file("outputs.tf", outputs_tf)
        
        self.log("Code generation complete.")

    def _write_file(self, filename: str, content: str):
        path = os.path.join(self.cfg.paths.output_dir, filename)
        with open(path, "w") as f:
            f.write(content)
        self.log(f"Written {filename}")
