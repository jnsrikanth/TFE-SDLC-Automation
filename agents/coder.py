import os
from agents.base_agent import BaseAgent

class CoderAgent(BaseAgent):
    def __init__(self, cfg):
        super().__init__("Coder", cfg)

    def write_code(self, blueprint: str):
        self.log("Generating Terraform code based on blueprint...")
        
        # Generate main.tf
        main_tf = self.think(self.cfg.prompts.coder.tasks.main.format(blueprint=blueprint))
        self._write_file("main.tf", self._clean_content(main_tf))
        
        # Generate variables.tf
        vars_tf = self.think(self.cfg.prompts.coder.tasks.variables.format(blueprint=blueprint))
        self._write_file("variables.tf", self._clean_content(vars_tf))
        
        # Generate outputs.tf
        outputs_tf = self.think(self.cfg.prompts.coder.tasks.outputs.format(blueprint=blueprint))
        self._write_file("outputs.tf", self._clean_content(outputs_tf))
        
        self.log("Code generation complete.")

    def _write_file(self, filename: str, content: str):
        path = os.path.join(self.cfg.paths.output_dir, filename)
        with open(path, "w") as f:
            f.write(content)
        self.log(f"Written {filename}")

    def _clean_content(self, content: str) -> str:
        import re
        # Try to find content within code blocks
        matches = re.findall(r"```(?:\w+)?\n(.*?)```", content, re.DOTALL)
        if matches:
            # Prefer block containing HCL keywords
            for match in matches:
                if "resource" in match or "variable" in match or "output" in match or "terraform" in match:
                    return match.strip()
            # Fallback to longest
            return max(matches, key=len).strip()
        
        # Fallback: return content as is
        return content.strip()
