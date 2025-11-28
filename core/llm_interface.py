import os
import vertexai
from vertexai.generative_models import GenerativeModel, GenerationConfig
from omegaconf import DictConfig
from dotenv import load_dotenv

load_dotenv()

class LLMInterface:
    """
    Interface for Google Vertex AI (Gemini).
    """
    
    def __init__(self, cfg: DictConfig):
        self.cfg = cfg
        self._setup_api()

    def _setup_api(self):
        project_id = self.cfg.get("GCP_PROJECT_ID") or os.getenv("GCP_PROJECT_ID")
        location = self.cfg.get("GCP_LOCATION") or os.getenv("GCP_LOCATION", "us-central1")
        
        print(f"[DEBUG] LLMInterface init: Project={project_id}, Location={location}, Model={self.cfg.llm.model}")

        if not project_id:
            print("[WARNING] No GCP_PROJECT_ID found. Agents will fail to think.")
            return

        vertexai.init(project=project_id, location=location)
        self.model = GenerativeModel(self.cfg.llm.model)

    def generate(self, prompt: str, context: str = "") -> str:
        """
        Generates text using the Vertex AI Gemini API.
        """
        try:
            # Construct a prompt with system context
            full_prompt = f"Context: {context}\n\nTask: {prompt}"
            
            response = self.model.generate_content(
                full_prompt,
                generation_config=GenerationConfig(
                    temperature=self.cfg.llm.temperature,
                    max_output_tokens=self.cfg.llm.max_tokens
                )
            )
            return response.text
        except Exception as e:
            print(f"[ERROR] Vertex AI API call failed: {e}")
            return f"Error generating content: {str(e)}"
