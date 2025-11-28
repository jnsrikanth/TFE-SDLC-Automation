import vertexai
from vertexai.generative_models import GenerativeModel

# Project ID from the gcloud output
project_id = "python-trading-app"
location = "us-central1"

print(f"Initializing Vertex AI with Project: {project_id}, Location: {location}")

try:
    vertexai.init(project=project_id, location=location)
    model = GenerativeModel("gemini-1.5-pro")
    
    print("Generating content...")
    response = model.generate_content("Say 'Hello from python-trading-app!'")
    print(f"\nResponse:\n{response.text}")

except Exception as e:
    print(f"\nFAILED: {e}")
