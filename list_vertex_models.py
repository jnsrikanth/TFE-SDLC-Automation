import os
import vertexai
from vertexai.generative_models import GenerativeModel
from dotenv import load_dotenv

load_dotenv()

project_id = os.getenv("GCP_PROJECT_ID")
location = os.getenv("GCP_LOCATION", "us-central1")

print(f"Initializing Vertex AI with Project: {project_id}, Location: {location}")

vertexai.init(project=project_id, location=location)

try:
    # Try a known stable model
    model_name = "gemini-1.0-pro" 
    print(f"Trying fallback model: {model_name}")
    model = GenerativeModel(model_name)
    response = model.generate_content("Hello")
    print(f"Success with {model_name}: {response.text}")
except Exception as e:
    print(f"Failed with {model_name}: {e}")

try:
    # Try another known stable model
    model_name = "gemini-1.5-pro-001" 
    print(f"Trying fallback model: {model_name}")
    model = GenerativeModel(model_name)
    response = model.generate_content("Hello")
    print(f"Success with {model_name}: {response.text}")
except Exception as e:
    print(f"Failed with {model_name}: {e}")
