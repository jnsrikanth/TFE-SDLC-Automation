import os
import vertexai
from vertexai.generative_models import GenerativeModel
from dotenv import load_dotenv

load_dotenv()

project_id = os.getenv("GCP_PROJECT_ID")
location = os.getenv("GCP_LOCATION", "us-central1")

print(f"Initializing Vertex AI with Project: {project_id}, Location: {location}")

try:
    vertexai.init(project=project_id, location=location)
    model = GenerativeModel("gemini-2.5-flash-lite")
    
    print("Generating content...")
    response = model.generate_content("Say 'Hello from Vertex AI!'")
    print(f"\nResponse:\n{response.text}")

except Exception as e:
    print(f"\nFAILED: {e}")
