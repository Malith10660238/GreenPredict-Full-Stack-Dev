from pydantic import BaseModel
from typing import Optional, List, ForwardRef
from datetime import datetime
from enum import Enum

# Email validation for Pydantic 1.x
try:
    from email_validator import validate_email
    EmailStr = str
except ImportError:
    EmailStr = str

class UserType(str, Enum):
    FARMER = "farmer"
    CONSUMER = "consumer"

class UserBase(BaseModel):
    """Base user model"""
    email: EmailStr
    first_name: str
    last_name: str
    user_type: UserType
    phone: Optional[str] = None
    location: Optional[str] = None
    bio: Optional[str] = None

class UserCreate(UserBase):
    """User creation model"""
    password: str

class UserUpdate(BaseModel):
    """User update model"""
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone: Optional[str] = None
    location: Optional[str] = None
    bio: Optional[str] = None
    farm_name: Optional[str] = None
    farm_size: Optional[str] = None
    farming_experience: Optional[str] = None
    certification: Optional[str] = None
    preferences: Optional[List[str]] = None

class FarmerProfile(BaseModel):
    """Farmer-specific profile data"""
    farm_name: Optional[str] = None
    farm_size: Optional[str] = None
    crops: Optional[List[str]] = None
    farming_experience: Optional[str] = None
    total_listings: int = 0
    total_sales: int = 0
    certification: Optional[str] = None

class ConsumerProfile(BaseModel):
    """Consumer-specific profile data"""
    preferences: Optional[List[str]] = None
    total_orders: int = 0
    total_spent: float = 0.0
    favorite_crops: Optional[List[str]] = None

class User(UserBase):
    """Complete user model"""
    uid: str
    display_name: str
    join_date: datetime
    rating: Optional[float] = None
    total_reviews: int = 0
    farmer_profile: Optional[FarmerProfile] = None
    consumer_profile: Optional[ConsumerProfile] = None
    profile_image_url: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class UserResponse(BaseModel):
    """User response model for API"""
    uid: str
    email: str
    first_name: str
    last_name: str
    display_name: str
    user_type: UserType
    phone: Optional[str] = None
    location: Optional[str] = None
    bio: Optional[str] = None
    join_date: datetime
    rating: Optional[float] = None
    total_reviews: int = 0
    farmer_profile: Optional[FarmerProfile] = None
    consumer_profile: Optional[ConsumerProfile] = None
    profile_image_url: Optional[str] = None

class LoginRequest(BaseModel):
    """Login request model"""
    email: EmailStr
    password: str

class LoginResponse(BaseModel):
    """Login response model"""
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

class RegisterRequest(UserCreate):
    """Registration request model"""
    pass

class RegisterResponse(BaseModel):
    """Registration response model"""
    message: str
    user: UserResponse
