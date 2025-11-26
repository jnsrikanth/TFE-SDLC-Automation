from core.llm_interface import LLMInterface
from core.config import config

class BaseAgent:
    def __init__(self, name: str):
        self.name = name
        self.llm = LLMInterface(config)
        self.config = config

    def log(self, message: str):
        print(f"[{self.name}] {message}")

    def think(self, prompt: str) -> str:
        self.log(f"Thinking about: {prompt[:50]}...")
        return self.llm.generate(prompt, context=self.name)
