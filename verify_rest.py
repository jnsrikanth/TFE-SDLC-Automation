import os
from dotenv import load_dotenv
import google.generativeai as genai

load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")

# Force REST transport
genai.configure(api_key=api_key, transport='rest')

try:
    print("Listing models (REST)...")
    for m in genai.list_models():
        if 'generateContent' in m.supported_generation_methods:
            print(m.name)
    
    print("\nGenerating content (REST)...")
    model = genai.GenerativeModel('gemini-1.5-pro')
    response = model.generate_content("Hello")
    print(response.text)

except Exception as e:
    print(f"Error: {e}")
