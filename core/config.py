import os
from dotenv import load_dotenv
from dataclasses import dataclass

load_dotenv()

@dataclass
class Config:
    PROJECT_ROOT: str = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    OUTPUT_DIR: str = os.path.join(PROJECT_ROOT, "output")
    TEMPLATES_DIR: str = os.path.join(PROJECT_ROOT, "templates")
    DOCS_DIR: str = os.path.join(PROJECT_ROOT, "docs")
    
    # LLM Configuration
    LLM_MODEL: str = "gemini-2.5-flash-lite"
    LLM_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    GCP_PROJECT_ID: str = os.getenv("GCP_PROJECT_ID", "")
    GCP_LOCATION: str = os.getenv("GCP_LOCATION", "us-central1")

    def ensure_dirs(self):
        os.makedirs(self.OUTPUT_DIR, exist_ok=True)

config = Config()
