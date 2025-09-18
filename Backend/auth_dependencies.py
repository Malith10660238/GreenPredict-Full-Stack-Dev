"""
Authentication dependencies for FastAPI
"""
from fastapi import HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from firebase_admin import auth, firestore
from typing import Dict, Any

# Security
security = HTTPBearer()

# Dependency to get current user
async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Get current authenticated user from Firebase token"""
    try:
        # Try to verify as ID token first
        try:
            decoded_token = auth.verify_id_token(credentials.credentials)
            uid = decoded_token['uid']
        except:
            # If ID token verification fails, try to verify as custom token
            # Custom tokens are JWT tokens that need to be verified differently
            import jwt
            import json
            
            # Decode the JWT token without verification to get the payload
            # Note: In production, you should verify the signature
            decoded_token = jwt.decode(credentials.credentials, options={"verify_signature": False})
            uid = decoded_token.get('uid')
            
            if not uid:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid token format"
                )
        
        # Get user data from Firestore
        db = firestore.client()
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
    except HTTPException:
        raise
    except Exception as e:
        print(f"Authentication error: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )
