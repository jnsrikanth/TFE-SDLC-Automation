import os
import vertexai
from vertexai.generative_models import GenerativeModel
from dotenv import load_dotenv

load_dotenv()

project_id = os.getenv("GCP_PROJECT_ID")
location = os.getenv("GCP_LOCATION", "us-central1")

print(f"Initializing Vertex AI with Project: {project_id}, Location: {location}")
vertexai.init(project=project_id, location=location)

models_to_try = [
    "gemini-1.5-pro-002",
    "gemini-1.5-flash-002",
    "gemini-1.5-flash",
    "gemini-1.5-pro-preview-0409",
    "gemini-1.0-pro-001",
    "gemini-1.0-pro",
    "gemini-pro"
]

for model_name in models_to_try:
    print(f"\nTrying model: {model_name}")
    try:
        model = GenerativeModel(model_name)
        response = model.generate_content("Hello")
        print(f"SUCCESS with {model_name}!")
        print(f"Response: {response.text}")
        break # Stop after first success
    except Exception as e:
        print(f"FAILED with {model_name}: {e}")
