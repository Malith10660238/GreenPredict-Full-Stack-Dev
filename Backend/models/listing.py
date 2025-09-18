from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from enum import Enum

class ListingStatus(str, Enum):
    ACTIVE = "active"
    SOLD = "sold"
    INACTIVE = "inactive"

class ListingBase(BaseModel):
    """Base listing model"""
    crop_name: str
    price: float
    quantity: int
    location: str
    description: str
    contact: str
    is_organic: bool = False

class ListingCreate(ListingBase):
    """Listing creation model"""
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

class Listing(ListingBase):
    """Complete listing model"""
    id: str
    farmer_id: str
    farmer_name: str
    rating: Optional[float] = None
    images: List[str] = []
    status: ListingStatus = ListingStatus.ACTIVE
    manufactured_date: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

class ListingResponse(BaseModel):
    """Listing response model for API"""
    id: str
    cropName: str  # Changed from crop_name to cropName for frontend compatibility
    farmerId: str  # Changed from farmer_id to farmerId
    farmerName: str  # Changed from farmer_name to farmerName
    price: float
    quantity: int
    location: str
    description: str
    contact: str
    isOrganic: bool  # Changed from is_organic to isOrganic
    rating: Optional[float] = None
    images: List[str] = []
    status: ListingStatus
    manufacturedDate: Optional[datetime] = None  # Changed from manufactured_date to manufacturedDate
    createdAt: datetime  # Changed from created_at to createdAt

    class Config:
        from_attributes = True

class ListingSearchParams(BaseModel):
    """Listing search parameters"""
    crop_type: Optional[str] = None
    location: Optional[str] = None
    price_min: Optional[float] = None
    price_max: Optional[float] = None
    is_organic: Optional[bool] = None
    limit: int = 20
    offset: int = 0

class ListingStats(BaseModel):
    """Listing statistics"""
    total_listings: int
    active_listings: int
    total_sales: int
    average_rating: float
