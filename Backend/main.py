from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import firebase_admin
from firebase_admin import credentials, auth, firestore
import os
from typing import Optional, List
import uvicorn

from routers import auth_router, prediction_router, listings_router, profile_router
from config import settings

# Initialize FastAPI app
app = FastAPI(
    title="GreenPredict Backend API",
    description="Backend API for GreenPredict - AI-powered agricultural prediction platform",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Firebase Admin SDK
def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    if not firebase_admin._apps:
        # Check if service account key file exists
        service_account_path = "serviceAccountKey.json"
        if os.path.exists(service_account_path):
            cred = credentials.Certificate(service_account_path)
            firebase_admin.initialize_app(cred)
        else:
            # For development, you can use default credentials
            # Make sure to set GOOGLE_APPLICATION_CREDENTIALS environment variable
            firebase_admin.initialize_app()
    
    return firestore.client()

# Initialize Firebase
db = initialize_firebase()

# Import authentication dependencies
from auth_dependencies import get_current_user

# Include routers
app.include_router(auth_router.router, prefix="/auth", tags=["Authentication"])
app.include_router(prediction_router.router, prefix="/prediction", tags=["AI Prediction"])
app.include_router(listings_router.router, prefix="/listings", tags=["Marketplace"])
app.include_router(profile_router.router, prefix="/profile", tags=["User Profile"])

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Welcome to GreenPredict Backend API",
        "version": "1.0.0",
        "status": "running"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "GreenPredict Backend"}

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8001,
        reload=True
    )
