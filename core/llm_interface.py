import os
import google.generativeai as genai
from omegaconf import DictConfig

class LLMInterface:
    """
    Interface for Google Gemini API.
    """
    
    def __init__(self, cfg: DictConfig):
        self.cfg = cfg
        self._setup_api()

    def _setup_api(self):
        api_key = self.cfg.llm.get("api_key")
        if not api_key:
            # Fallback to env var if not in config
            api_key = os.getenv("GEMINI_API_KEY")
            
        if not api_key:
            print("[WARNING] No GEMINI_API_KEY found. Agents will fail to think.")
            return

        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel(self.cfg.llm.model)

    def generate(self, prompt: str, context: str = "") -> str:
        """
        Generates text using the Gemini API.
        """
        try:
            # Construct a prompt with system context
            full_prompt = f"Context: {context}\n\nTask: {prompt}"
            
            response = self.model.generate_content(
                full_prompt,
                generation_config=genai.types.GenerationConfig(
                    temperature=self.cfg.llm.temperature,
                    max_output_tokens=self.cfg.llm.max_tokens
                )
            )
            return response.text
        except Exception as e:
            print(f"[ERROR] Gemini API call failed: {e}")
            return f"Error generating content: {str(e)}"
