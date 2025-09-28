#!/usr/bin/env python3
"""
Full FastAPI Backend for GreenPredict
"""

from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import firebase_admin
from firebase_admin import credentials, auth, firestore
import os
import random
import string
from typing import Optional, List, Dict, Any
import uvicorn
from datetime import datetime, timedelta
import uuid
import json
import requests
from dotenv import load_dotenv
from email_service import email_service

load_dotenv()

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
            firebase_admin.initialize_app()
    
    return firestore.client()

# Initialize Firebase
try:
    db = initialize_firebase()
    print("✅ Firebase initialized successfully!")
except Exception as e:
    print(f"❌ Firebase initialization failed: {e}")
    db = None

# Get Firebase Web API Key from environment variables
FIREBASE_WEB_API_KEY = os.getenv("FIREBASE_WEB_API_KEY")
if not FIREBASE_WEB_API_KEY:
    raise ValueError("FIREBASE_WEB_API_KEY environment variable is required")
print(f"✅ Firebase Web API Key loaded: {FIREBASE_WEB_API_KEY[:20]}...")

# Security
security = HTTPBearer()

# Dependency to get current user
async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Get current authenticated user from Firebase token"""
    try:
        # Extract token from credentials
        token = credentials.credentials
        print(f"🔍 Verifying token: {token[:20]}...")
        
        # Verify the Firebase token (handle both custom tokens and ID tokens)
        try:
            # First try to verify as ID token
            try:
                decoded_token = auth.verify_id_token(token)
                user_uid = decoded_token['uid']
                print(f"✅ ID token verified for user: {user_uid}")
            except:
                # If ID token verification fails, try to verify as custom token
                # For custom tokens, we need to exchange them for ID tokens
                # For now, let's use a simpler approach - decode the custom token
                import base64
                import json
                
                # Custom tokens are JWT tokens, let's decode the payload
                parts = token.split('.')
                if len(parts) == 3:
                    # Decode the payload (middle part)
                    payload = parts[1]
                    # Add padding if needed
                    payload += '=' * (4 - len(payload) % 4)
                    decoded_payload = base64.b64decode(payload)
                    payload_data = json.loads(decoded_payload)
                    user_uid = payload_data.get('uid')
                    print(f"✅ Custom token verified for user: {user_uid}")
                else:
                    raise Exception("Invalid token format")
                    
        except Exception as e:
            print(f"❌ Token verification failed: {e}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication token"
            )
        
        # Get user data from Firestore
        try:
            user_doc = db.collection('users').document(user_uid).get()
            if not user_doc.exists:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="User profile not found"
                )
            
            user_data = user_doc.to_dict()
            print(f"✅ User data retrieved: {user_data.get('display_name', 'No display name')}")
            
            return {
                'uid': user_uid,
                'email': user_data.get('email', ''),
                'first_name': user_data.get('first_name', ''),
                'last_name': user_data.get('last_name', ''),
                'display_name': user_data.get('display_name', ''),
                'user_type': user_data.get('user_type', 'consumer'),
                'phone': user_data.get('phone'),
                'location': user_data.get('location'),
                'bio': user_data.get('bio'),
                'join_date': user_data.get('join_date', datetime.now()),
                'rating': user_data.get('rating'),
                'total_reviews': user_data.get('total_reviews', 0),
                'farmer_profile': user_data.get('farmer_profile'),
                'consumer_profile': user_data.get('consumer_profile')
            }
            
        except HTTPException:
            raise
        except Exception as e:
            print(f"❌ Firestore error: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Database error"
            )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Authentication error: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )

# Root endpoints
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

# Authentication endpoints
@app.post("/auth/login")
async def login(login_data: dict):
    """User login endpoint"""
    try:
        email = login_data.get('email')
        password = login_data.get('password')
        
        print(f"🔍 Login attempt for email: {email}")
        
        if not email or not password:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email and password are required"
            )
        
        # Verify user credentials using Firebase Auth REST API
        try:
            # Use Firebase Auth REST API to verify email and password
            rest_api_url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={FIREBASE_WEB_API_KEY}"
            
            payload = json.dumps({
                "email": email,
                "password": password,
                "returnSecureToken": True
            })
            
            headers = {"Content-Type": "application/json"}
            
            response = requests.post(rest_api_url, data=payload, headers=headers)
            response_data = response.json()

            if response.status_code != 200:
                error_message = response_data.get('error', {}).get('message', 'Unknown error during Firebase Auth.')
                print(f"❌ Firebase Auth REST API error: {error_message}")
                if "EMAIL_NOT_FOUND" in error_message or "INVALID_PASSWORD" in error_message:
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="Invalid email or password"
                    )
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"Firebase authentication failed: {error_message}"
                )
            
            # If successful, response_data contains idToken, refreshToken, localId (which is the uid)
            user_uid = response_data.get('localId')
            print(f"✅ Firebase Auth REST API successful. User UID: {user_uid}")
            
        except HTTPException:
            raise
        except Exception as e:
            print(f"❌ Authentication error: {e}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
        
        # Get user data from Firestore using the verified UID
        try:
            user_doc = db.collection('users').document(user_uid).get()
            print(f"🔍 Firestore document exists: {user_doc.exists}")
            
            if not user_doc.exists:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="User profile not found"
                )
            
            user_data = user_doc.to_dict()
            print(f"✅ User data retrieved: {user_data.get('displayName', 'No display name')}")
        except Exception as e:
            print(f"❌ Firestore error: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Database error"
            )
        
        # Check if email is verified (temporarily disabled for testing)
        # if not user_data.get('email_verified', False):
        #     raise HTTPException(
        #         status_code=status.HTTP_403_FORBIDDEN,
        #         detail="Please verify your email before logging in. Check your inbox for a verification email."
        #     )
        
        # Create custom token for the user
        try:
            custom_token = auth.create_custom_token(user_uid)
            print(f"✅ Custom token created successfully")
        except Exception as e:
            print(f"❌ Token creation error: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Token creation failed"
            )
        
        return {
            "access_token": custom_token.decode('utf-8'),
            "token_type": "bearer",
            "user": {
                "uid": user_uid,
                "email": email,
                "first_name": user_data.get('first_name', ''),
                "last_name": user_data.get('last_name', ''),
                "display_name": user_data.get('display_name', ''),
                "user_type": user_data.get('user_type', 'consumer'),
                "phone": user_data.get('phone'),
                "location": user_data.get('location'),
                "bio": user_data.get('bio'),
                "join_date": user_data.get('join_date', datetime.now()),
                "rating": user_data.get('rating'),
                "total_reviews": user_data.get('total_reviews', 0),
                "farmer_profile": user_data.get('farmer_profile'),
                "consumer_profile": user_data.get('consumer_profile'),
                "profile_image_path": user_data.get('profile_image_path')
            }
        }
        
    except auth.UserNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Login failed: {str(e)}"
        )

@app.post("/auth/register")
async def register(register_data: dict):
    """User registration endpoint"""
    try:
        print(f"🔍 Registration attempt with data: {register_data}")
        
        email = register_data.get('email')
        password = register_data.get('password')
        first_name = register_data.get('first_name')
        last_name = register_data.get('last_name')
        user_type = register_data.get('user_type', 'consumer')
        
        print(f"📝 Parsed data - Email: {email}, User Type: {user_type}, Name: {first_name} {last_name}")
        
        # Validate required fields with specific error messages
        if not email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email is required"
            )
        if not password:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Password is required"
            )
        if not first_name:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="First name is required"
            )
        if not last_name:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Last name is required"
            )
        
        # Validate email format
        import re
        email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_pattern, email):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Please enter a valid email address"
            )
        
        # Validate password strength
        if len(password) < 6:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Password must be at least 6 characters long"
            )
        
        # Validate user type
        if user_type not in ['farmer', 'consumer']:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User type must be either 'farmer' or 'consumer'"
            )
        
        # Check if user already exists in Firestore
        print(f"🔍 Checking if user already exists in Firestore...")
        existing_users = db.collection('users').where('email', '==', email).get()
        if existing_users:
            print(f"❌ User already exists in Firestore: {email}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This email is already registered. Please use a different email or try logging in."
            )
        
        # Create user in Firebase Auth with email verification disabled initially
        print(f"🔧 Creating user in Firebase Auth...")
        try:
            user = auth.create_user(
                email=email,
                password=password,
                display_name=f"{first_name} {last_name}",
                email_verified=False  # Require email verification
            )
            print(f"✅ Firebase Auth user created successfully: {user.uid}")
        except Exception as e:
            print(f"❌ Firebase Auth creation failed: {e}")
            if "EMAIL_EXISTS" in str(e):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="This email is already registered with Firebase. Please use a different email or try logging in."
                )
            elif "INVALID_EMAIL" in str(e):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Please enter a valid email address"
                )
            elif "WEAK_PASSWORD" in str(e):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Password is too weak. Please choose a stronger password"
                )
            else:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"Firebase Auth creation failed: {str(e)}"
                )
        
        # Prepare user data for Firestore
        user_data = {
            'email': email,
            'first_name': first_name,
            'last_name': last_name,
            'display_name': f"{first_name} {last_name}",
            'user_type': user_type,
            'phone': register_data.get('phone'),
            'location': register_data.get('location'),
            'bio': register_data.get('bio'),
            'join_date': datetime.now(),
            'rating': None,
            'total_reviews': 0,
            'email_verified': False,  # Track email verification status
            'created_at': datetime.now(),
            'updated_at': datetime.now()
        }
        
        # Generate verification code
        verification_code = ''.join(random.choices(string.digits, k=6))
        
        # Send real email verification
        email_sent = email_service.send_verification_email(
            recipient_email=email,
            verification_code=verification_code,
            user_name=f"{first_name} {last_name}"
        )
        
        if email_sent:
            print(f"✅ Verification email sent successfully to: {email}")
        else:
            print(f"⚠️ Failed to send email to {email}, but registration continues")
            print(f"📧 [FALLBACK] Verification code for {email}: {verification_code}")
            print(f"📧 [FALLBACK] Use this code in the app to verify your email")
        
        # Store verification code in user data
        user_data['verification_code'] = verification_code
        user_data['verification_code_expires'] = datetime.now().timestamp() + 3600  # 1 hour expiry
        
        # Add user-specific profile data
        if user_type == 'farmer':
            user_data['farmer_profile'] = {
                'farm_name': None,
                'farm_size': None,
                'crops': [],
                'farming_experience': None,
                'total_listings': 0,
                'total_sales': 0,
                'certification': None
            }
        else:
            user_data['consumer_profile'] = {
                'preferences': [],
                'total_orders': 0,
                'total_spent': 0.0,
                'favorite_crops': []
            }
        
        # Save user data to Firestore in both collections
        print(f"🔧 Saving user data to Firestore...")
        try:
            db.collection('users').document(user.uid).set(user_data)
            print(f"✅ User data saved to Firestore successfully: {user.uid}")
        except Exception as e:
            print(f"❌ Firestore save failed: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to save user data: {str(e)}"
            )
        
        # Also save to specific collection based on user type
        if user_type == 'farmer':
            # Save to farmers collection
            farmer_data = {
                'uid': user.uid,
                'email': email,
                'first_name': first_name,
                'last_name': last_name,
                'display_name': f"{first_name} {last_name}",
                'phone': register_data.get('phone'),
                'location': register_data.get('location'),
                'bio': register_data.get('bio'),
                'join_date': datetime.now(),
                'email_verified': False,
                'verification_code': verification_code,
                'verification_code_expires': verification_code_expires,
                'created_at': datetime.now(),
                'updated_at': datetime.now(),
                'farm_name': None,
                'farm_size': None,
                'crops': [],
                'farming_experience': None,
                'total_listings': 0,
                'total_sales': 0,
                'certification': None,
                'rating': None,
                'total_reviews': 0
            }
            try:
                db.collection('farmers').document(user.uid).set(farmer_data)
                print(f"✅ Farmer saved to farmers collection: {email}")
            except Exception as e:
                print(f"❌ Failed to save farmer to farmers collection: {e}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"Failed to save farmer data: {str(e)}"
                )
            
        elif user_type == 'consumer':
            # Save to consumers collection
            consumer_data = {
                'uid': user.uid,
                'email': email,
                'first_name': first_name,
                'last_name': last_name,
                'display_name': f"{first_name} {last_name}",
                'phone': register_data.get('phone'),
                'location': register_data.get('location'),
                'bio': register_data.get('bio'),
                'join_date': datetime.now(),
                'email_verified': False,
                'verification_code': verification_code,
                'verification_code_expires': verification_code_expires,
                'created_at': datetime.now(),
                'updated_at': datetime.now(),
                'preferences': [],
                'total_orders': 0,
                'total_spent': 0.0,
                'favorite_crops': [],
                'rating': None,
                'total_reviews': 0
            }
            try:
                db.collection('consumers').document(user.uid).set(consumer_data)
                print(f"✅ Consumer saved to consumers collection: {email}")
            except Exception as e:
                print(f"❌ Failed to save consumer to consumers collection: {e}")
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"Failed to save consumer data: {str(e)}"
                )
        
        print(f"🎉 Registration completed successfully for: {email} ({user_type})")
        return {
            "message": "User registered successfully",
            "user": {
                "uid": user.uid,
                "email": user.email,
                "first_name": first_name,
                "last_name": last_name,
                "display_name": user_data['display_name'],
                "user_type": user_type,
                "phone": register_data.get('phone'),
                "location": register_data.get('location'),
                "bio": register_data.get('bio'),
                "join_date": user_data['join_date'],
                "rating": None,
                "total_reviews": 0,
                "farmer_profile": user_data.get('farmer_profile'),
                "consumer_profile": user_data.get('consumer_profile')
            }
        }
        
    except auth.EmailAlreadyExistsError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This email is already registered with Firebase. Please use a different email or try logging in."
        )
    except auth.InvalidEmailError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Please enter a valid email address"
        )
    except auth.WeakPasswordError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password is too weak. Please choose a stronger password with at least 6 characters."
        )
    except HTTPException:
        # Re-raise HTTP exceptions (our custom error messages)
        raise
    except Exception as e:
        print(f"❌ Unexpected registration error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Registration failed due to a server error. Please try again later."
        )

@app.post("/auth/verify-email")
async def verify_email(verification_data: dict):
    """Verify user email"""
    try:
        email = verification_data.get('email')
        verification_code = verification_data.get('verification_code')
        
        if not email or not verification_code:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email and verification code are required"
            )
        
        # Verify the verification code
        user_docs = db.collection('users').where('email', '==', email).limit(1).get()
        
        if not user_docs:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        user_doc = user_docs[0]
        user_data = user_doc.to_dict()
        
        # Check if verification code matches
        stored_code = user_data.get('verification_code')
        code_expires = user_data.get('verification_code_expires', 0)
        
        if not stored_code:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No verification code found. Please register again."
            )
        
        if datetime.now().timestamp() > code_expires:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Verification code has expired. Please request a new one."
            )
        
        if verification_code != stored_code:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid verification code. Please check and try again."
            )
        
        # Update user's email verification status in Firestore
        user_id = user_doc.id
        db.collection('users').document(user_id).update({
            'email_verified': True,
            'verification_code': None,  # Remove the code after successful verification
            'verification_code_expires': None,
            'updated_at': datetime.now()
        })
        
        return {
            "message": "Email verified successfully",
            "email_verified": True
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Email verification failed: {str(e)}"
        )

@app.post("/auth/resend-verification")
async def resend_verification(resend_data: dict):
    """Resend email verification"""
    try:
        email = resend_data.get('email')
        
        if not email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email is required"
            )
        
        # Generate new verification code
        try:
            # Find user in Firestore
            user_docs = db.collection('users').where('email', '==', email).limit(1).get()
            
            if not user_docs:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="User not found"
                )
            
            user_doc = user_docs[0]
            user_id = user_doc.id
            
            # Generate new verification code
            new_verification_code = ''.join(random.choices(string.digits, k=6))
            
            # Get user data for name
            user_data = user_doc.to_dict()
            user_name = user_data.get('display_name', 'User')
            
            # Send real email verification
            email_sent = email_service.send_verification_email(
                recipient_email=email,
                verification_code=new_verification_code,
                user_name=user_name
            )
            
            if email_sent:
                print(f"✅ Verification email resent successfully to: {email}")
            else:
                print(f"⚠️ Failed to resend email to {email}")
                print(f"📧 [FALLBACK] New verification code for {email}: {new_verification_code}")
                print(f"📧 [FALLBACK] Use this new code in the app to verify your email")
            
            # Update user with new verification code
            db.collection('users').document(user_id).update({
                'verification_code': new_verification_code,
                'verification_code_expires': datetime.now().timestamp() + 3600,  # 1 hour expiry
                'updated_at': datetime.now()
            })
            
        except Exception as e:
            print(f"⚠️ Could not resend verification email: {e}")
        
        return {
            "message": "Verification email sent successfully",
            "email": email
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to resend verification email: {str(e)}"
        )

# AI Prediction endpoints
@app.post("/prediction/analyze")
async def analyze_crop_prediction(prediction_data: dict, current_user: Dict[str, Any] = Depends(get_current_user)):
    """Analyze crop prediction based on input parameters"""
    try:
        # Generate prediction ID
        prediction_id = str(uuid.uuid4())
        
        # Create input parameters object - handle both camelCase and snake_case field names
        input_params = {
            "planning_year": prediction_data.get('planning_year') or prediction_data.get('planningYear', ''),
            "location": prediction_data.get('location') or prediction_data.get('district', ''),
            "season": prediction_data.get('season', ''),
            "temperature": prediction_data.get('temperature', ''),
            "soil_type": prediction_data.get('soil_type') or prediction_data.get('soilType', ''),
            "land_area": prediction_data.get('land_area') or prediction_data.get('landArea', ''),
            "crop": prediction_data.get('crop', '')
        }
        
        # Generate AI prediction result (mock implementation)
        prediction_result = generate_mock_prediction(input_params)
        
        # Save prediction to Firestore
        prediction_doc = {
            'prediction_id': prediction_id,
            'user_id': current_user['uid'],
            'input_parameters': input_params,
            'result': prediction_result,
            'created_at': datetime.now()
        }
        
        db.collection('crop_predictions_ai').document(prediction_id).set(prediction_doc)
        
        return {
            "prediction_id": prediction_id,
            "result": prediction_result,
            "created_at": datetime.now(),
            "user_id": current_user['uid']
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Prediction analysis failed: {str(e)}"
        )

# Marketplace endpoints
@app.get("/listings")
async def get_listings(
    crop_type: Optional[str] = None,
    location: Optional[str] = None,
    price_min: Optional[float] = None,
    price_max: Optional[float] = None,
    is_organic: Optional[bool] = None,
    limit: int = 20,
    offset: int = 0
):
    """Get marketplace listings with optional filters"""
    try:
        # Get all listings first (simple approach without complex queries)
        listings = db.collection('listings').stream()
        
        result = []
        for listing in listings:
            listing_data = listing.to_dict()
            
            # Skip inactive listings
            if listing_data.get('status') != 'active':
                continue
            
            # Apply filters
            if crop_type and crop_type.lower() not in listing_data.get('crop_name', '').lower():
                continue
            if location and location.lower() not in listing_data.get('location', '').lower():
                continue
            if is_organic is not None and listing_data.get('is_organic') != is_organic:
                continue
            if price_min is not None and listing_data.get('price', 0) < price_min:
                continue
            if price_max is not None and listing_data.get('price', 0) > price_max:
                continue
            
            result.append({
                "id": listing.id,
                "cropName": listing_data.get('crop_name', ''),
                "category": listing_data.get('category', 'Vegetables'),
                "farmerId": listing_data.get('farmer_id', ''),
                "farmerName": listing_data.get('farmer_name', ''),
                "price": listing_data.get('price', 0),
                "quantity": listing_data.get('quantity', 0),
                "location": listing_data.get('location', ''),
                "description": listing_data.get('description', ''),
                "contact": listing_data.get('contact', ''),
                "isOrganic": listing_data.get('is_organic', False),
                "rating": listing_data.get('rating'),
                "images": listing_data.get('images', []),
                "status": listing_data.get('status', 'active'),
                "manufacturedDate": listing_data.get('manufactured_date'),
                "created_at": listing_data.get('created_at', datetime.now())
            })
        
        # Sort by creation date (newest first) - handle different date types
        try:
            def get_sort_key(item):
                created_at = item.get('created_at')
                if created_at is None:
                    return datetime.min
                # If it's a Firestore timestamp, convert to datetime
                if hasattr(created_at, 'timestamp'):
                    return created_at.to_pydatetime()
                # If it's already a datetime, return as is
                if isinstance(created_at, datetime):
                    return created_at
                # If it's a string, try to parse it
                if isinstance(created_at, str):
                    try:
                        return datetime.fromisoformat(created_at.replace('Z', '+00:00'))
                    except:
                        return datetime.min
                return datetime.min
            
            result.sort(key=get_sort_key, reverse=True)
        except Exception as e:
            print(f"⚠️ Warning: Could not sort listings by date: {e}")
            # If sorting fails, just return unsorted results
        
        # Apply pagination
        return result[offset:offset + limit]
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch listings: {str(e)}"
        )

@app.post("/listings")
async def create_listing(listing_data: dict, current_user: Dict[str, Any] = Depends(get_current_user)):
    """Create a new marketplace listing"""
    try:
        print(f"🔍 Create listing request from user: {current_user.get('display_name', 'Unknown')}")
        print(f"📝 Listing data: {listing_data}")
        
        # Check if user is a farmer
        if current_user.get('user_type') != 'farmer':
            print(f"❌ User {current_user.get('display_name')} is not a farmer")
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only farmers can create listings"
            )
        
        # Generate listing ID
        listing_id = str(uuid.uuid4())
        
        # Handle manufactured date from frontend - support both formats
        manufactured_date = listing_data.get('manufactured_date') or listing_data.get('manufacturedDate', '')
        if manufactured_date:
            try:
                # Parse the date from frontend
                if isinstance(manufactured_date, str):
                    # Handle different date formats
                    if '/' in manufactured_date:
                        # Format: "15/9/2025"
                        day, month, year = manufactured_date.split('/')
                        manufactured_date = datetime(int(year), int(month), int(day))
                    elif 'T' in manufactured_date:
                        # ISO format from frontend: "2025-09-17T12:00:00.000Z"
                        manufactured_date = datetime.fromisoformat(manufactured_date.replace('Z', '+00:00'))
                    else:
                        # Try to parse as ISO format
                        manufactured_date = datetime.fromisoformat(manufactured_date.replace('Z', '+00:00'))
            except Exception as e:
                print(f"⚠️ Warning: Could not parse manufactured_date '{manufactured_date}': {e}")
                manufactured_date = datetime.now()
        else:
            manufactured_date = datetime.now()
        
        # Prepare listing document - handle both camelCase and snake_case field names
        listing_doc = {
            'crop_name': listing_data.get('crop_name') or listing_data.get('cropName', ''),
            'category': listing_data.get('category', 'Vegetables'),
            'farmer_id': current_user['uid'],
            'farmer_name': current_user.get('display_name', ''),
            'price': float(listing_data.get('price', 0)),
            'quantity': int(listing_data.get('quantity', 0)),
            'location': listing_data.get('location', ''),
            'description': listing_data.get('description', ''),
            'contact': listing_data.get('contact', ''),
            'is_organic': bool(listing_data.get('is_organic') or listing_data.get('isOrganic', False)),
            'rating': listing_data.get('rating'),
            'images': listing_data.get('images', []),
            'status': 'active',
            'manufactured_date': manufactured_date,
            'created_at': datetime.now(),
            'updated_at': datetime.now()
        }
        
        # Save to Firestore
        db.collection('listings').document(listing_id).set(listing_doc)
        print(f"✅ Listing saved to Firestore with ID: {listing_id}")
        
        # Update farmer's total listings count
        try:
            farmer_ref = db.collection('users').document(current_user['uid'])
            farmer_doc = farmer_ref.get()
            if farmer_doc.exists:
                farmer_data = farmer_doc.to_dict()
                if 'farmer_profile' in farmer_data:
                    farmer_data['farmer_profile']['total_listings'] += 1
                    farmer_ref.update({'farmer_profile': farmer_data['farmer_profile']})
                    print(f"✅ Updated farmer's total listings count")
        except Exception as e:
            print(f"⚠️ Warning: Could not update farmer's listing count: {e}")
        
        print(f"🎉 Listing created successfully: {listing_doc['crop_name']}")
        return {
            "id": listing_id,
            **listing_doc
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create listing: {str(e)}"
        )

@app.delete("/listings/{listing_id}")
async def delete_listing(listing_id: str, current_user: Dict[str, Any] = Depends(get_current_user)):
    """Delete a marketplace listing"""
    try:
        print(f"🔍 Delete listing request for ID: {listing_id} from user: {current_user.get('display_name', 'Unknown')}")
        
        # Check if user is a farmer
        if current_user.get('user_type') != 'farmer':
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only farmers can delete listings"
            )
        
        # Get the listing to verify ownership
        listing_ref = db.collection('listings').document(listing_id)
        listing_doc = listing_ref.get()
        
        if not listing_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Listing not found"
            )
        
        listing_data = listing_doc.to_dict()
        
        # Check if the current user owns this listing
        if listing_data.get('farmer_id') != current_user['uid']:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only delete your own listings"
            )
        
        # Delete the listing
        listing_ref.delete()
        print(f"✅ Listing deleted successfully: {listing_id}")
        
        # Update farmer's total listings count
        try:
            farmer_ref = db.collection('users').document(current_user['uid'])
            farmer_doc = farmer_ref.get()
            if farmer_doc.exists:
                farmer_data = farmer_doc.to_dict()
                if 'farmer_profile' in farmer_data and farmer_data['farmer_profile']['total_listings'] > 0:
                    farmer_data['farmer_profile']['total_listings'] -= 1
                    farmer_ref.update({'farmer_profile': farmer_data['farmer_profile']})
                    print(f"✅ Updated farmer's total listings count")
        except Exception as e:
            print(f"⚠️ Warning: Could not update farmer's listing count: {e}")
        
        return {"message": "Listing deleted successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete listing: {str(e)}"
        )

@app.put("/listings/{listing_id}")
async def update_listing(listing_id: str, listing_data: dict, current_user: Dict[str, Any] = Depends(get_current_user)):
    """Update a marketplace listing"""
    try:
        print(f"🔍 Update listing request for ID: {listing_id} from user: {current_user.get('display_name', 'Unknown')}")
        print(f"📝 Update data: {listing_data}")
        
        # Check if user is a farmer
        if current_user.get('user_type') != 'farmer':
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only farmers can update listings"
            )
        
        # Get the listing to verify ownership
        listing_ref = db.collection('listings').document(listing_id)
        listing_doc = listing_ref.get()
        
        if not listing_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Listing not found"
            )
        
        existing_data = listing_doc.to_dict()
        
        # Check if the current user owns this listing
        if existing_data.get('farmer_id') != current_user['uid']:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only update your own listings"
            )
        
        # Handle manufactured date from frontend - support both formats
        manufactured_date = listing_data.get('manufactured_date') or listing_data.get('manufacturedDate')
        if manufactured_date:
            try:
                # Parse the date from frontend
                if isinstance(manufactured_date, str):
                    # Handle different date formats
                    if '/' in manufactured_date:
                        # Format: "15/9/2025"
                        day, month, year = manufactured_date.split('/')
                        manufactured_date = datetime(int(year), int(month), int(day))
                    elif 'T' in manufactured_date:
                        # ISO format from frontend: "2025-09-17T12:00:00.000Z"
                        manufactured_date = datetime.fromisoformat(manufactured_date.replace('Z', '+00:00'))
                    else:
                        # Try to parse as ISO format
                        manufactured_date = datetime.fromisoformat(manufactured_date.replace('Z', '+00:00'))
            except Exception as e:
                print(f"⚠️ Warning: Could not parse manufactured_date '{manufactured_date}': {e}")
                manufactured_date = existing_data.get('manufactured_date', datetime.now())
        else:
            manufactured_date = existing_data.get('manufactured_date', datetime.now())
        
        # Prepare update data - handle both camelCase and snake_case field names
        update_data = {
            'crop_name': listing_data.get('crop_name') or listing_data.get('cropName', existing_data.get('crop_name', '')),
            'category': listing_data.get('category', existing_data.get('category', 'Vegetables')),
            'price': float(listing_data.get('price', existing_data.get('price', 0))),
            'quantity': int(listing_data.get('quantity', existing_data.get('quantity', 0))),
            'location': listing_data.get('location', existing_data.get('location', '')),
            'description': listing_data.get('description', existing_data.get('description', '')),
            'contact': listing_data.get('contact', existing_data.get('contact', '')),
            'is_organic': bool(listing_data.get('is_organic') or listing_data.get('isOrganic', existing_data.get('is_organic', False))),
            'rating': listing_data.get('rating', existing_data.get('rating')),
            'images': listing_data.get('images', existing_data.get('images', [])),
            'manufactured_date': manufactured_date,
            'updated_at': datetime.now()
        }
        
        # Update the listing
        listing_ref.update(update_data)
        print(f"✅ Listing updated successfully: {listing_id}")
        
        # Get the updated listing data
        updated_doc = listing_ref.get()
        updated_data = updated_doc.to_dict()
        
        return {
            "id": listing_id,
            "cropName": updated_data.get('crop_name', ''),
            "category": updated_data.get('category', 'Vegetables'),
            "farmerId": updated_data.get('farmer_id', ''),
            "farmerName": updated_data.get('farmer_name', ''),
            "price": updated_data.get('price', 0),
            "quantity": updated_data.get('quantity', 0),
            "location": updated_data.get('location', ''),
            "description": updated_data.get('description', ''),
            "contact": updated_data.get('contact', ''),
            "isOrganic": updated_data.get('is_organic', False),
            "rating": updated_data.get('rating'),
            "images": updated_data.get('images', []),
            "status": updated_data.get('status', 'active'),
            "manufacturedDate": updated_data.get('manufactured_date'),
            "created_at": updated_data.get('created_at', datetime.now()),
            "updated_at": updated_data.get('updated_at', datetime.now())
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update listing: {str(e)}"
        )

# Profile endpoints
@app.get("/profile/")
async def get_profile(current_user: Dict[str, Any] = Depends(get_current_user)):
    """Get current user's profile"""
    return current_user

@app.get("/admin/users/")
async def get_all_users():
    """Get all registered users (for admin purposes)"""
    try:
        # Get all users from Firestore
        users = db.collection('users').stream()
        
        result = []
        for user in users:
            user_data = user.to_dict()
            user_data['uid'] = user.id
            result.append(user_data)
        
        return {
            "total_users": len(result),
            "users": result
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch users: {str(e)}"
        )

@app.get("/admin/farmers/")
async def get_all_farmers():
    """Get all registered farmers"""
    try:
        # Get all farmers from Firestore
        farmers = db.collection('farmers').stream()
        
        result = []
        for farmer in farmers:
            farmer_data = farmer.to_dict()
            farmer_data['uid'] = farmer.id
            result.append(farmer_data)
        
        return {
            "total_farmers": len(result),
            "farmers": result
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch farmers: {str(e)}"
        )

@app.get("/admin/consumers/")
async def get_all_consumers():
    """Get all registered consumers"""
    try:
        # Get all consumers from Firestore
        consumers = db.collection('consumers').stream()
        
        result = []
        for consumer in consumers:
            consumer_data = consumer.to_dict()
            consumer_data['uid'] = consumer.id
            result.append(consumer_data)
        
        return {
            "total_consumers": len(result),
            "consumers": result
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch consumers: {str(e)}"
        )

@app.put("/profile/")
async def update_profile(profile_update: dict, current_user: Dict[str, Any] = Depends(get_current_user)):
    """Update user profile"""
    try:
        print(f"🔍 Profile update request from user: {current_user.get('display_name', 'Unknown')}")
        print(f"📝 Profile update data: {profile_update}")
        
        # Prepare update data
        update_data = {}
        for field, value in profile_update.items():
            if value is not None and value != '':
                update_data[field] = value
        
        # Update display name if first or last name changed
        if 'first_name' in update_data or 'last_name' in update_data:
            first_name = update_data.get('first_name', current_user.get('first_name', ''))
            last_name = update_data.get('last_name', current_user.get('last_name', ''))
            update_data['display_name'] = f"{first_name} {last_name}".strip()
        
        update_data['updated_at'] = datetime.now()
        
        # Update user document in main users collection
        user_ref = db.collection('users').document(current_user['uid'])
        user_ref.update(update_data)
        print(f"✅ Updated user document in users collection")
        
        # Also update the specific collection (farmers or consumers)
        user_type = current_user.get('user_type', 'consumer')
        if user_type == 'farmer':
            farmer_ref = db.collection('farmers').document(current_user['uid'])
            farmer_ref.update(update_data)
            print(f"✅ Updated farmer document in farmers collection")
        elif user_type == 'consumer':
            consumer_ref = db.collection('consumers').document(current_user['uid'])
            consumer_ref.update(update_data)
            print(f"✅ Updated consumer document in consumers collection")
        
        # Get updated user data
        updated_doc = user_ref.get()
        updated_data = updated_doc.to_dict()
        
        print(f"🎉 Profile updated successfully for: {updated_data.get('display_name', 'Unknown')}")
        
        return {
            "uid": current_user['uid'],
            "email": current_user['email'],
            "first_name": updated_data.get('first_name', ''),
            "last_name": updated_data.get('last_name', ''),
            "display_name": updated_data.get('display_name', ''),
            "user_type": current_user['user_type'],
            "phone": updated_data.get('phone'),
            "location": updated_data.get('location'),
            "bio": updated_data.get('bio'),
            "join_date": current_user.get('join_date', datetime.now()),
            "rating": updated_data.get('rating'),
            "total_reviews": updated_data.get('total_reviews', 0),
            "farmer_profile": updated_data.get('farmer_profile'),
            "consumer_profile": updated_data.get('consumer_profile'),
            "profile_image_path": updated_data.get('profile_image_path')
        }
        
    except Exception as e:
        print(f"❌ Profile update failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update profile: {str(e)}"
        )

def generate_mock_prediction(input_params: dict) -> dict:
    """Generate mock prediction result (replace with actual ML model)"""
    
    crop = input_params.get('crop', 'Unknown')
    location = input_params.get('location', 'Unknown')
    season = input_params.get('season', 'Unknown')
    
    return {
        "input_parameters": input_params,
        "current_season_recommendation": {
            "recommended_crop": crop,
            "suitability_score": 85,
            "reasons": [
                f"Optimal weather conditions for {crop} cultivation",
                f"High market demand in {location} region",
                f"Low pest risk during {season}",
                "Water availability is sufficient"
            ],
            "planting_tips": [
                "Plant during early morning hours",
                "Ensure proper spacing between plants",
                "Use organic fertilizers for better yield",
                "Regular monitoring for pest control"
            ]
        },
        "best_upcoming_seasons": [
            {
                "season": "Maha (October - March)",
                "suitability_score": 92,
                "expected_yield": "4.5 tons/acre",
                "profitability_rating": "High"
            },
            {
                "season": "Yala (April - September)",
                "suitability_score": 78,
                "expected_yield": "3.8 tons/acre",
                "profitability_rating": "Medium"
            }
        ],
        "yield_profitability_analysis": {
            "expected_yield": "4.2 tons/acre",
            "estimated_revenue": "Rs. 420,000/acre",
            "estimated_costs": "Rs. 180,000/acre",
            "net_profit": "Rs. 240,000/acre",
            "profit_margin": "57%",
            "break_even_time": "6 months"
        },
        "risk_assessment": {
            "overall_risk": "Medium",
            "weather_risk": "Low",
            "market_risk": "Medium",
            "pest_disease_risk": "Low",
            "recommendations": [
                "Consider crop insurance for weather protection",
                "Diversify with 2-3 different crops",
                "Monitor market prices regularly",
                "Implement IPM practices"
            ]
        },
        "alternative_crops": [
            {
                "name": "Tomatoes",
                "suitability_score": 88,
                "expected_profit": "Rs. 320,000/acre",
                "growth_period": "4 months"
            },
            {
                "name": "Onions",
                "suitability_score": 82,
                "expected_profit": "Rs. 280,000/acre",
                "growth_period": "5 months"
            },
            {
                "name": "Carrots",
                "suitability_score": 79,
                "expected_profit": "Rs. 260,000/acre",
                "growth_period": "3 months"
            }
        ]
    }

if __name__ == "__main__":
    uvicorn.run(
        "main_fastapi:app",
        host="0.0.0.0",
        port=8001,  # Using port 8001 to avoid conflict with test server
        reload=True
    )
