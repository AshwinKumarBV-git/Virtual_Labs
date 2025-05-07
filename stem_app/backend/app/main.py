from fastapi import FastAPI, File, UploadFile, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import List
from datetime import datetime
import os
from dotenv import load_dotenv
from io import BytesIO
from PIL import Image # For image handling with Gemini
import re # Import regex module

# Import Google Generative AI
import google.generativeai as genai

from .models import Lab, QuizResultInput, QuizResultOutput

# Database imports
from .database import create_db_and_tables, get_db, add_quiz_result
from sqlalchemy.ext.asyncio import AsyncSession

# --- Load Environment Variables --- #
load_dotenv() # Load variables from .env file

# --- Configure Gemini API --- #
GEMINI_API_KEY = "AIzaSyBzVOxcuo4HMRaxCqoBPVO4sRXNxpMyl_E"
if GEMINI_API_KEY:
    try:
        genai.configure(api_key=GEMINI_API_KEY)
        print("Gemini API Key configured.")
    except Exception as e:
        print(f"Error configuring Gemini API: {e}")
        GEMINI_API_KEY = None # Ensure it's None if config fails
else:
    print("Warning: GEMINI_API_KEY not found in environment variables.")

app = FastAPI()

# --- Startup Event --- #
@app.on_event("startup")
async def on_startup():
    print("Creating database and tables...")
    await create_db_and_tables()
    print("Database setup complete.")

# --- CORS Configuration --- #
origins = [
    "*", # Allow all origins for development. Restrict in production!
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"], # Allows all methods (GET, POST, etc.)
    allow_headers=["*"], # Allows all headers
)

# --- Dummy Data (Labs only now) --- #
dummy_labs = [
    Lab(id=1, name="Density Lab", description="Explore the concept of density with various liquids."),
    Lab(id=2, name="Soil pH Testing", description="Test the pH levels of different soil samples."),
    Lab(id=3, name="Osmosis in Plant Cells", description="Observe the process of osmosis using potato slices."),
]

# --- API Endpoints --- #

@app.get("/")
async def read_root():
    return {"message": "Welcome to the STEM App Backend!"}

@app.get("/labs", response_model=List[Lab])
async def get_labs():
    """Returns the list of available labs."""
    return dummy_labs

@app.post("/quiz", response_model=QuizResultOutput)
async def submit_quiz(result: QuizResultInput, db: AsyncSession = Depends(get_db)):
    """Receives quiz results and saves them to the database."""
    print(f"Received Quiz Result: Lab ID {result.lab_id}, Score {result.score}")

    saved_result = await add_quiz_result(db=db, result=result)

    # Convert SQLAlchemy model to Pydantic model for response
    # Note: SQLAlchemy model fields should match Pydantic field names
    return QuizResultOutput.model_validate(saved_result)

@app.post("/image")
async def analyze_image(file: UploadFile = File(...)):
    """Accepts an image, sends it to Gemini for explanation in English."""
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=500, detail="Gemini API key not configured on server.")

    print(f"Received image: {file.filename}, Content-Type: {file.content_type}")

    try:
        # Read image bytes
        image_bytes = await file.read()
        if not image_bytes:
            raise HTTPException(status_code=400, detail="No image data received.")

        # Load image using PIL to ensure it's valid and for Gemini input
        img = Image.open(BytesIO(image_bytes))
        # Optional: You might want to check img.format, size, etc.

        # --- Prepare Prompt and Model --- #
        # model_name = 'gemini-pro-vision' # Check latest available free vision model if 1.5 flash isn't free
        model_name = 'gemini-1.5-flash-latest' # Usually supports multimodal input
        model = genai.GenerativeModel(model_name)

        # Update prompt to explicitly ask for English
        prompt_parts = [
            f"Explain the scientific concept, diagram, or equation shown in the image in English. Focus on concepts suitable for grades 7-10. If it is not scientific, state that.",
            img, # Pass the PIL image object directly
        ]

        # --- Generate Content with Gemini --- #
        print(f"Sending request to Gemini model: {model_name}...")
        response = await model.generate_content_async(prompt_parts)
        # Note: Use generate_content_async for FastAPI's async nature

        # --- Process Response --- # #
        # Check for safety blocks before accessing text
        if not response.candidates:
             print("Gemini Response Blocked or Empty. Feedback:", response.prompt_feedback)
             # Attempt to access reason if available (structure might vary)
             block_reason = "unknown"
             try:
                 block_reason = response.prompt_feedback.block_reason.name
             except Exception:
                 pass
             raise HTTPException(status_code=500, detail=f"Explanation generation failed (Safety Block: {block_reason})")

        explanation = response.text
        print(f"Received explanation from Gemini.")

        # Clean Markdown for TTS
        cleaned_explanation = re.sub(r'\*\*', '', explanation) # Remove bold (**)
        cleaned_explanation = re.sub(r'\*', '', cleaned_explanation) # Remove italics (*)
        # Add more rules if needed (e.g., for #, _, etc.)

        print(f"Cleaned explanation for TTS.")

        return {"explanation": cleaned_explanation} # Return cleaned text

    except genai.types.generation_types.BlockedPromptException as e:
        print(f"Gemini API Error (Blocked Prompt): {e}")
        raise HTTPException(status_code=500, detail=f"Explanation generation failed (Safety Block)")
    except Exception as e:
        print(f"Error during Gemini API call or image processing: {e}")
        # More specific error checking could be added here (e.g., invalid API key, quota exceeded)
        raise HTTPException(status_code=500, detail="Failed to get explanation from AI model.")

# To run the app (from the backend directory):
# cd stem_app/backend
# ../venv/bin/activate  (or venv\Scripts\activate on Windows)
# uvicorn app.main:app --reload 