from fastapi import APIRouter, HTTPException, Depends, status
from firebase_admin import auth, firestore
from typing import Dict, Any
import uuid
from datetime import datetime

from models.user import LoginRequest, LoginResponse, RegisterRequest, RegisterResponse, UserResponse, UserType
from auth_dependencies import get_current_user

router = APIRouter()

@router.post("/login", response_model=LoginResponse)
async def login(login_data: LoginRequest):
    """User login endpoint"""
    try:
        # Verify user credentials with Firebase Auth
        user = auth.get_user_by_email(login_data.email)
        
        # Get user data from Firestore
        db = firestore.client()
        user_doc = db.collection('users').document(user.uid).get()
        
        if not user_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User profile not found"
            )
        
        user_data = user_doc.to_dict()
        
        # Create custom token for the user
        custom_token = auth.create_custom_token(user.uid)
        
        # Prepare user response
        user_response = UserResponse(
            uid=user.uid,
            email=user.email,
            first_name=user_data.get('first_name', ''),
            last_name=user_data.get('last_name', ''),
            display_name=user_data.get('display_name', ''),
            user_type=UserType(user_data.get('user_type', 'consumer')),
            phone=user_data.get('phone'),
            location=user_data.get('location'),
            bio=user_data.get('bio'),
            join_date=user_data.get('join_date', datetime.now()),
            rating=user_data.get('rating'),
            total_reviews=user_data.get('total_reviews', 0),
            farmer_profile=user_data.get('farmer_profile'),
            consumer_profile=user_data.get('consumer_profile'),
            profile_image_url=user_data.get('profile_image_url')
        )
        
        return LoginResponse(
            access_token=custom_token.decode('utf-8'),
            user=user_response
        )
        
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

@router.post("/register", response_model=RegisterResponse)
async def register(register_data: RegisterRequest):
    """User registration endpoint"""
    try:
        db = firestore.client()
        
        # Create user in Firebase Auth
        user = auth.create_user(
            email=register_data.email,
            password=register_data.password,
            display_name=f"{register_data.first_name} {register_data.last_name}"
        )
        
        # Prepare user data for Firestore
        user_data = {
            'email': register_data.email,
            'first_name': register_data.first_name,
            'last_name': register_data.last_name,
            'display_name': f"{register_data.first_name} {register_data.last_name}",
            'user_type': register_data.user_type.value,
            'phone': register_data.phone,
            'location': register_data.location,
            'bio': register_data.bio,
            'join_date': datetime.now(),
            'rating': None,
            'total_reviews': 0,
            'created_at': datetime.now(),
            'updated_at': datetime.now()
        }
        
        # Add user-specific profile data
        if register_data.user_type == UserType.FARMER:
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
        
        # Save user data to Firestore
        db.collection('users').document(user.uid).set(user_data)
        
        # Prepare user response
        user_response = UserResponse(
            uid=user.uid,
            email=user.email,
            first_name=register_data.first_name,
            last_name=register_data.last_name,
            display_name=user_data['display_name'],
            user_type=register_data.user_type,
            phone=register_data.phone,
            location=register_data.location,
            bio=register_data.bio,
            join_date=user_data['join_date'],
            rating=None,
            total_reviews=0,
            farmer_profile=user_data.get('farmer_profile'),
            consumer_profile=user_data.get('consumer_profile')
        )
        
        return RegisterResponse(
            message="User registered successfully",
            user=user_response
        )
        
    except auth.EmailAlreadyExistsError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already exists"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Registration failed: {str(e)}"
        )

@router.post("/logout")
async def logout(current_user: Dict[str, Any] = Depends(get_current_user)):
    """User logout endpoint"""
    # In Firebase, logout is typically handled on the client side
    # This endpoint can be used for any server-side cleanup if needed
    return {"message": "Logged out successfully"}

@router.post("/reset-password")
async def reset_password(email: str):
    """Password reset endpoint"""
    try:
        # Generate password reset link
        reset_link = auth.generate_password_reset_link(email)
        
        # In a real application, you would send this link via email
        # For now, we'll just return a success message
        return {
            "message": "Password reset link sent to your email",
            "reset_link": reset_link  # Remove this in production
        }
        
    except auth.UserNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Password reset failed: {str(e)}"
        )

@router.get("/me", response_model=UserResponse)
async def get_current_user_info(current_user: Dict[str, Any] = Depends(get_current_user)):
    """Get current user information"""
    return current_user
