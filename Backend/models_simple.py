from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

class UserType(str, Enum):
    FARMER = "farmer"
    CONSUMER = "consumer"

class UserBase(BaseModel):
    """Base user model"""
    email: str
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
    farmer_profile: Optional[Dict[str, Any]] = None
    consumer_profile: Optional[Dict[str, Any]] = None

class LoginRequest(BaseModel):
    """Login request model"""
    email: str
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

# Listing Models
class ListingStatus(str, Enum):
    ACTIVE = "active"
    SOLD = "sold"
    INACTIVE = "inactive"

class ListingCreate(BaseModel):
    """Listing creation model"""
    crop_name: str
    price: float
    quantity: int
    location: str
    description: str
    contact: str
    is_organic: bool = False
    images: Optional[List[str]] = []

class ListingUpdate(BaseModel):
    """Listing update model"""
    crop_name: Optional[str] = None
    price: Optional[float] = None
    quantity: Optional[int] = None
    location: Optional[str] = None
    description: Optional[str] = None
    contact: Optional[str] = None
    is_organic: Optional[bool] = None
    images: Optional[List[str]] = None
    status: Optional[ListingStatus] = None

class ListingResponse(BaseModel):
    """Listing response model for API"""
    id: str
    crop_name: str
    farmer_id: str
    farmer_name: str
    price: float
    quantity: int
    location: str
    description: str
    contact: str
    is_organic: bool
    rating: Optional[float] = None
    images: List[str] = []
    status: ListingStatus
    manufactured_date: Optional[datetime] = None
    created_at: datetime

# Prediction Models
class InputParameters(BaseModel):
    """Input parameters for AI prediction"""
    planning_year: str
    location: str
    season: str
    temperature: str
    soil_type: str
    land_area: str
    crop: str

class CurrentSeasonRecommendation(BaseModel):
    """Current season recommendation"""
    recommended_crop: str
    suitability_score: int
    reasons: List[str]
    planting_tips: List[str]

class SeasonRecommendation(BaseModel):
    """Season recommendation"""
    season: str
    suitability_score: int
    expected_yield: str
    profitability_rating: str

class YieldProfitabilityAnalysis(BaseModel):
    """Yield and profitability analysis"""
    expected_yield: str
    estimated_revenue: str
    estimated_costs: str
    net_profit: str
    profit_margin: str
    break_even_time: str

class RiskAssessment(BaseModel):
    """Risk assessment"""
    overall_risk: str
    weather_risk: str
    market_risk: str
    pest_disease_risk: str
    recommendations: List[str]

class AlternativeCrop(BaseModel):
    """Alternative crop suggestion"""
    name: str
    suitability_score: int
    expected_profit: str
    growth_period: str

class AIPredictionResult(BaseModel):
    """Complete AI prediction result"""
    input_parameters: InputParameters
    current_season_recommendation: CurrentSeasonRecommendation
    best_upcoming_seasons: List[SeasonRecommendation]
    yield_profitability_analysis: YieldProfitabilityAnalysis
    risk_assessment: RiskAssessment
    alternative_crops: List[AlternativeCrop]

class PredictionRequest(BaseModel):
    """Prediction request model"""
    planning_year: str
    location: str
    season: str
    temperature: str
    soil_type: str
    land_area: str
    crop: str

class PredictionResponse(BaseModel):
    """Prediction response model"""
    prediction_id: str
    result: AIPredictionResult
    created_at: datetime
    user_id: Optional[str] = None
