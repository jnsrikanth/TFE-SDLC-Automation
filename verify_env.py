from dotenv import load_dotenv
import os

load_dotenv()
key = os.getenv("GEMINI_API_KEY")

if key:
    print(f"SUCCESS: GEMINI_API_KEY found (length: {len(key)})")
else:
    print("FAILURE: GEMINI_API_KEY not found in environment or .env file")
