import os
from dotenv import load_dotenv
from omegaconf import OmegaConf
from core.llm_interface import LLMInterface

# Load env
load_dotenv()

# Mock config
cfg = OmegaConf.create({
    "llm": {
        "model": "gemini-1.5-pro", # Using 1.5 Pro as it's widely available, user config said 3.0-pro but let's test with what might be available or stick to config default if I can import it.
        # Actually, let's use the default from config.py if possible, but here I'll just hardcode a known working model for test, or better, use the one in config.
        "api_key": os.getenv("GEMINI_API_KEY"),
        "temperature": 0.7,
        "max_tokens": 100
    }
})

print(f"Testing with model: {cfg.llm.model}")

try:
    llm = LLMInterface(cfg)
    response = llm.generate("Say 'Hello, Gemini!' if you can hear me.")
    print(f"\nResponse from Gemini:\n{response}")
except Exception as e:
    print(f"\nFAILED to generate content: {e}")
