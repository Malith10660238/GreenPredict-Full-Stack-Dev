# GreenPredict Backend API

A FastAPI-based backend for the GreenPredict agricultural prediction platform, integrated with Firebase for authentication and data storage.

## Features

- **Authentication**: Firebase Auth integration for user management
- **AI Predictions**: Crop recommendation and analysis endpoints
- **Marketplace**: Crop listing management for farmers and consumers
- **User Profiles**: Comprehensive user profile management
- **Real-time Data**: Firestore integration for real-time data storage

## Tech Stack

- **FastAPI**: Modern, fast web framework for building APIs
- **Firebase Admin SDK**: Authentication and Firestore database
- **Pydantic**: Data validation and serialization
- **Uvicorn**: ASGI server for running the application

## Project Structure

```
Backend/
├── main.py                 # FastAPI application entry point
├── config.py              # Application configuration
├── requirements.txt       # Python dependencies
├── env.example           # Environment variables template
├── models/               # Pydantic models
│   ├── __init__.py
│   ├── user.py          # User-related models
│   ├── listing.py       # Marketplace listing models
│   └── prediction.py    # AI prediction models
└── routers/             # API route handlers
    ├── __init__.py
    ├── auth_router.py   # Authentication endpoints
    ├── prediction_router.py  # AI prediction endpoints
    ├── listings_router.py    # Marketplace endpoints
    └── profile_router.py     # User profile endpoints
```

## Setup Instructions

### 1. Prerequisites

- Python 3.8 or higher
- Firebase project with Firestore enabled
- Firebase service account key

### 2. Installation

1. Clone the repository and navigate to the Backend directory:
```bash
cd Backend
```

2. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

### 3. Firebase Setup

1. Go to your Firebase Console and create a new project (if you haven't already)
2. Enable Firestore Database
3. Go to Project Settings > Service Accounts
4. Generate a new private key and download the JSON file
5. Rename the downloaded file to `serviceAccountKey.json` and place it in the Backend directory

### 4. Environment Configuration

1. Copy the environment template:
```bash
cp env.example .env
```

2. Update the `.env` file with your Firebase project details:
```env
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY_ID=your-private-key-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYour private key here\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=your-service-account@your-project.iam.gserviceaccount.com
FIREBASE_CLIENT_ID=your-client-id
```

### 5. Running the Application

Start the development server:
```bash
python main.py
```

The API will be available at `http://localhost:8000`

### 6. API Documentation

Once the server is running, you can access:
- **Interactive API docs**: `http://localhost:8000/docs`
- **ReDoc documentation**: `http://localhost:8000/redoc`

## API Endpoints

### Authentication (`/auth`)
- `POST /auth/login` - User login
- `POST /auth/register` - User registration
- `POST /auth/logout` - User logout
- `POST /auth/reset-password` - Password reset
- `GET /auth/me` - Get current user info

### AI Predictions (`/prediction`)
- `POST /prediction/analyze` - Analyze crop prediction
- `GET /prediction/history` - Get user's prediction history
- `GET /prediction/{prediction_id}` - Get specific prediction

### Marketplace (`/listings`)
- `GET /listings/` - Get marketplace listings (with filters)
- `POST /listings/` - Create new listing (farmers only)
- `GET /listings/{listing_id}` - Get specific listing
- `PUT /listings/{listing_id}` - Update listing
- `DELETE /listings/{listing_id}` - Delete listing
- `GET /listings/farmer/{farmer_id}` - Get farmer's listings
- `GET /listings/stats/overview` - Get marketplace statistics

### User Profiles (`/profile`)
- `GET /profile/` - Get current user's profile
- `PUT /profile/` - Update user profile
- `PUT /profile/farmer` - Update farmer-specific profile
- `PUT /profile/consumer` - Update consumer-specific profile
- `GET /profile/{user_id}` - Get another user's public profile
- `DELETE /profile/` - Delete user account

## Data Models

### User Types
- **Farmer**: Can create listings, has farming-specific profile data
- **Consumer**: Can browse listings, has consumer-specific preferences

### Key Features
- **Firebase Authentication**: Secure user authentication
- **Firestore Integration**: Real-time data storage
- **CORS Support**: Cross-origin requests for Flutter app
- **Input Validation**: Pydantic models for data validation
- **Error Handling**: Comprehensive error responses

## Development

### Running Tests
```bash
pytest
```

### Code Formatting
```bash
black .
```

### Linting
```bash
flake8 .
```

## Deployment

For production deployment:

1. Set `DEBUG=False` in your environment variables
2. Use a production ASGI server like Gunicorn with Uvicorn workers
3. Set up proper CORS origins for your Flutter app
4. Use environment variables for sensitive configuration
5. Set up proper logging and monitoring

## Integration with Flutter Frontend

The backend is designed to work seamlessly with the Flutter frontend. Update the `baseUrl` in your Flutter `ApiService` to point to your deployed backend URL.

## Support

For issues and questions, please refer to the project documentation or create an issue in the repository.
