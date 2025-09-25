from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class InquiryMessage(BaseModel):
    sender_id: str
    message: str
    timestamp: datetime

class InquiryCreate(BaseModel):
    farmer_id: str
    product_id: str
    message: str

class InquiryResponse(BaseModel):
    id: str
    consumer_id: str
    farmer_id: str
    product_id: str
    product_name: Optional[str] = None
    farmer_name: Optional[str] = None
    consumer_name: Optional[str] = None
    status: str
    created_at: datetime
    updated_at: datetime
    messages: List[InquiryMessage] = []

class InquiryMessageCreate(BaseModel):
    message: str

class InquiryStatusUpdate(BaseModel):
    status: str
