"""
Simple backend without image processing for testing
"""
from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import uvicorn
import json

# Initialize FastAPI app
app = FastAPI(
    title="GreenPredict Backend API (Simple)",
    description="Simple backend API for GreenPredict",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Simple authentication
security = HTTPBearer()

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Simple authentication for testing"""
    try:
        if credentials.credentials.startswith("test_"):
            return {
                "uid": "test_user_123",
                "email": "testuser@example.com",
                "first_name": "Test",
                "last_name": "User",
                "display_name": "Test User",
                "user_type": "farmer"
            }
        else:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials"
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
        "message": "Welcome to GreenPredict Backend API (Simple)",
        "version": "1.0.0",
        "status": "running"
    }

@app.get("/ping")
async def ping():
    """Lightweight ping endpoint"""
    return {"pong": True}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "GreenPredict Backend (Simple)"}

# Simple auth endpoints
@app.post("/auth/register")
async def register(register_data: dict):
    """Simple registration for testing"""
    email = register_data.get("email")
    password = register_data.get("password")
    firstName = register_data.get("firstName", "New")
    lastName = register_data.get("lastName", "User")
    userType = register_data.get("userType", "farmer")
    
    # Accept any registration for testing
    if email and password:
        user_data = {
            "uid": f"user_{hash(email) % 10000}",
            "email": email,
            "first_name": firstName,
            "last_name": lastName,
            "display_name": f"{firstName} {lastName}",
            "user_type": userType
        }
        
        return {
            "access_token": f"test_token_{hash(email) % 10000}",
            "user": user_data
        }
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email and password are required"
        )

@app.post("/auth/login")
async def login(login_data: dict):
    """Simple login for testing"""
    email = login_data.get("email")
    password = login_data.get("password")
    
    # Accept any email/password for testing
    if email and password:
        user_data = {
            "uid": "test_user_123",
            "email": email,
            "first_name": "Test",
            "last_name": "User",
            "display_name": "Test User",
            "user_type": "farmer"
        }
        
        return {
            "access_token": "test_token_123",
            "user": user_data
        }
    else:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )

@app.get("/profile/")
async def get_profile(current_user: dict = Depends(get_current_user)):
    """Get user profile"""
    return current_user

@app.post("/profile/upload-image")
async def upload_profile_image(file, current_user: dict = Depends(get_current_user)):
    """Upload profile image (mock)"""
    return {
        "message": "Profile image uploaded successfully",
        "image_url": "http://localhost:8001/static/test_image.jpg"
    }

if __name__ == "__main__":
    uvicorn.run(
        "main_simple:app",
        host="0.0.0.0",
        port=8001,
        reload=True
    )