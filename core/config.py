import os
from dataclasses import dataclass

@dataclass
class Config:
    PROJECT_ROOT: str = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    OUTPUT_DIR: str = os.path.join(PROJECT_ROOT, "output")
    TEMPLATES_DIR: str = os.path.join(PROJECT_ROOT, "templates")
    DOCS_DIR: str = os.path.join(PROJECT_ROOT, "docs")
    
    # LLM Configuration
    LLM_MODEL: str = "gemini-3.0-pro"
    LLM_API_KEY: str = os.getenv("GEMINI_API_KEY", "")

    def ensure_dirs(self):
        os.makedirs(self.OUTPUT_DIR, exist_ok=True)

config = Config()
