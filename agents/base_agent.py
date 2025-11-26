from omegaconf import DictConfig
from core.llm_interface import LLMInterface

class BaseAgent:
    def __init__(self, name: str, cfg: DictConfig):
        self.name = name
        self.cfg = cfg
        self.llm = LLMInterface(cfg)

    def log(self, message: str):
        print(f"[{self.name}] {message}")

    def think(self, prompt: str) -> str:
        self.log(f"Thinking about: {prompt[:50]}...")
        return self.llm.generate(prompt, context=self.name)
