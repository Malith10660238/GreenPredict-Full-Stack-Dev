from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import firebase_admin
from firebase_admin import credentials, auth, firestore
import os
from typing import Optional, List, Dict, Any
import uvicorn
from datetime import datetime

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
try:
    db = initialize_firebase()
    print("Firebase initialized successfully!")
except Exception as e:
    print(f"Firebase initialization failed: {e}")
    db = None

# Security
security = HTTPBearer()

# Dependency to get current user
async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Get current authenticated user from Firebase token"""
    try:
        # Verify the Firebase token
        decoded_token = auth.verify_id_token(credentials.credentials)
        uid = decoded_token['uid']
        
        # Get user data from Firestore
        user_doc = db.collection('users').document(uid).get()
        if user_doc.exists:
            user_data = user_doc.to_dict()
            user_data['uid'] = uid
            return user_data
        else:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )

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

# Simple test endpoints
@app.get("/test")
async def test_endpoint():
    """Test endpoint"""
    return {"message": "Backend is working!", "timestamp": datetime.now()}

@app.get("/test-firebase")
async def test_firebase():
    """Test Firebase connection"""
    if db is None:
        return {"error": "Firebase not initialized"}
    
    try:
        # Test Firestore connection
        test_doc = db.collection('test').document('connection').get()
        return {"message": "Firebase connection successful", "firestore": "connected"}
    except Exception as e:
        return {"error": f"Firebase connection failed: {str(e)}"}

if __name__ == "__main__":
    uvicorn.run(
        "main_simple:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
