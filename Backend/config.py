from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    """Application settings"""
    
    # API Settings
    api_title: str = "GreenPredict Backend API"
    api_version: str = "1.0.0"
    debug: bool = True
    
    # Firebase Settings
    firebase_project_id: Optional[str] = None
    firebase_private_key_id: Optional[str] = None
    firebase_private_key: Optional[str] = None
    firebase_client_email: Optional[str] = None
    firebase_client_id: Optional[str] = None
    firebase_auth_uri: Optional[str] = None
    firebase_token_uri: Optional[str] = None
    
    # Database Settings
    firestore_database_id: str = "(default)"
    
    # Security Settings
    secret_key: str = "your-secret-key-here"  # Change this in production
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    
    # CORS Settings
    allowed_origins: list = ["*"]  # Change this in production
    
    # File Upload Settings
    max_file_size: int = 10 * 1024 * 1024  # 10MB
    allowed_file_types: list = ["image/jpeg", "image/png", "image/webp"]
    
    class Config:
        env_file = ".env"
        case_sensitive = False
        extra = "allow"

# Create settings instance
settings = Settings()
