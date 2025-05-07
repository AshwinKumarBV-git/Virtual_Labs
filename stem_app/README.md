# STEM Education App

This project provides an interactive application aimed at STEM education, particularly for students in grades 7-10. It consists of a Flutter-based frontend and a Python FastAPI backend.

## Features

*   **Interactive Labs:** Browse and learn from a list of predefined STEM labs (e.g., Density, pH Testing, Osmosis).
*   **Image Analysis:** Upload an image of a scientific concept, diagram, or equation. The app uses the Google Gemini AI model via the backend to provide an explanation.
*   **Text-to-Speech:** Hear explanations read aloud (implemented in the frontend).
*   **Quizzing:** Test your knowledge with quizzes related to the labs.
*   **Progress Tracking:** Quiz results are saved to track learning progress (stored locally in the frontend and potentially synced or viewed via the backend - database exists).
*   **Multi-language Support:** The frontend is set up for internationalization.

## Project Structure

```
stem_app/
├── backend/         # Python FastAPI backend
│   ├── app/         # Main application code
│   │   ├── main.py       # FastAPI app, API endpoints (labs, quiz, image analysis)
│   │   ├── database.py   # SQLAlchemy setup for SQLite
│   │   ├── models.py     # Pydantic and SQLAlchemy models
│   │   └── requirements.txt # Backend dependencies (FastAPI, Uvicorn, SQLAlchemy, Gemini, etc.)
│   ├── venv/        # Python virtual environment
│   └── quiz_results.db # SQLite database for quiz results
│
├── frontend/        # Flutter frontend application
│   ├── lib/         # Main Dart code
│   │   ├── main.dart    # App entry point
│   │   └── screens/     # UI screens for different features
│   ├── assets/        # App assets (e.g., fonts)
│   ├── pubspec.yaml # Frontend dependencies (Flutter SDK, http, image_picker, tts, etc.)
│   ├── ios/         # iOS specific code
│   ├── android/     # Android specific code
│   └── web/         # Web specific code (if configured)
│
└── README.md        # This file
```

*(Note: The top-level `lib/` directory seems unused or potentially misplaced based on the current structure.)*

## Technologies Used

*   **Frontend:** Flutter, Dart
*   **Backend:** Python, FastAPI, Uvicorn, SQLAlchemy, SQLite
*   **AI:** Google Gemini API (for image analysis)
*   **Database:** SQLite

## Setup and Running

### Backend

1.  Navigate to the backend directory: `cd stem_app/backend`
2.  Create/activate a Python virtual environment (e.g., using `venv`).
3.  Install dependencies: `pip install -r app/requirements.txt`
4.  Set up your Google Gemini API Key: Create a `.env` file in the `stem_app/backend/app` directory and add your key:
    ```
    GEMINI_API_KEY=YOUR_API_KEY_HERE
    ```
5.  Run the backend server: `uvicorn app.main:app --reload --host 0.0.0.0 --port 8000` (The `--host 0.0.0.0` makes it accessible from your mobile device on the same network).

### Frontend

1.  Ensure you have the Flutter SDK installed.
2.  Navigate to the frontend directory: `cd stem_app/frontend`
3.  Install dependencies: `flutter pub get`
4.  Make sure the backend server is running and accessible from your device/emulator. Update the API endpoint URL in the frontend code if necessary (likely in a configuration file or constants).
5.  Run the app on your desired platform (emulator, device, web):
    *   `flutter run` (select target device when prompted)
    *   `flutter run -d chrome` (for web, if configured) 