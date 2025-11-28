from agents.base_agent import BaseAgent

class ArchitectAgent(BaseAgent):
    def __init__(self, cfg):
        super().__init__("Architect", cfg)

    def design_module(self, requirements: str) -> str:
        self.log(f"Analyzing requirements: {requirements}")
        prompt = self.cfg.prompts.architect.task.format(requirements=requirements)
        blueprint = self.think(prompt)
        
        # Save blueprint to file
        import os
        os.makedirs(self.cfg.paths.output_dir, exist_ok=True)
        with open(os.path.join(self.cfg.paths.output_dir, "blueprint.md"), "w") as f:
            f.write(blueprint)
            
        self.log("Blueprint created and saved to blueprint.md")
        return blueprint
