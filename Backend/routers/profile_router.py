from fastapi import APIRouter, HTTPException, Depends, status, UploadFile, File
from firebase_admin import firestore
from typing import Dict, Any
from datetime import datetime
import base64

from models.user import UserUpdate, UserResponse, FarmerProfile, ConsumerProfile
from auth_dependencies import get_current_user
from local_storage_service import local_storage_service

router = APIRouter()

@router.get("/", response_model=UserResponse)
async def get_profile(current_user: Dict[str, Any] = Depends(get_current_user)):
    """Get current user's profile"""
    return current_user

@router.put("/", response_model=UserResponse)
async def update_profile(
    profile_update: UserUpdate,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Update user profile"""
    try:
        db = firestore.client()
        
        print(f"🔵 Backend - Profile update request received: {profile_update.dict(exclude_unset=True)}")
        print(f"🔵 Backend - Current user: {current_user.get('uid')} ({current_user.get('user_type')})")
        
        # Prepare update data
        update_data = {}
        farmer_profile_data = {}
        
        # Handle basic profile fields
        for field, value in profile_update.dict(exclude_unset=True).items():
            if value is not None:
                if field in ['farm_name', 'farm_size', 'farming_experience', 'certification']:
                    farmer_profile_data[field] = value
                    print(f"🔵 Backend - Adding to farmer_profile_data: {field} = {value}")
                else:
                    update_data[field] = value
                    print(f"🔵 Backend - Adding to update_data: {field} = {value}")
        
        print(f"🔵 Backend - Final update_data: {update_data}")
        print(f"🔵 Backend - Final farmer_profile_data: {farmer_profile_data}")
        
        # Update display name if first or last name changed
        if 'first_name' in update_data or 'last_name' in update_data:
            first_name = update_data.get('first_name', current_user.get('first_name', ''))
            last_name = update_data.get('last_name', current_user.get('last_name', ''))
            update_data['display_name'] = f"{first_name} {last_name}"
        
        update_data['updated_at'] = datetime.now()
        
        # Update user document
        user_ref = db.collection('users').document(current_user['uid'])
        
        # Update basic profile data
        if update_data:
            user_ref.update(update_data)
            print(f"✅ Updated user document in users collection")
        
        # Update farmer profile if user is a farmer and has farmer-specific data
        if current_user.get('user_type') == 'farmer' and farmer_profile_data:
            # Get current farmer profile
            current_doc = user_ref.get()
            current_data = current_doc.to_dict()
            current_farmer_profile = current_data.get('farmer_profile', {})
            
            # Merge with new farmer profile data
            updated_farmer_profile = {**current_farmer_profile, **farmer_profile_data}
            
            user_ref.update({
                'farmer_profile': updated_farmer_profile,
                'updated_at': datetime.now()
            })
            
            # Also update the farmers collection
            farmer_ref = db.collection('farmers').document(current_user['uid'])
            farmer_update_data = {
                "firstName": update_data.get('first_name'),
                "lastName": update_data.get('last_name'),
                "displayName": update_data.get('display_name'),
                "phone": update_data.get('phone'),
                "location": update_data.get('location'),
                "bio": update_data.get('bio'),
                "updatedAt": datetime.now()
            }
            # Remove None values
            farmer_update_data = {k: v for k, v in farmer_update_data.items() if v is not None}
            
            if farmer_update_data:
                farmer_ref.update(farmer_update_data)
                print(f"✅ Updated farmer document in farmers collection")
        
        # Update consumer profile if user is a consumer
        elif current_user.get('user_type') == 'consumer':
            # Also update the consumers collection
            consumer_ref = db.collection('consumers').document(current_user['uid'])
            consumer_update_data = {
                "firstName": update_data.get('first_name'),
                "lastName": update_data.get('last_name'),
                "displayName": update_data.get('display_name'),
                "phone": update_data.get('phone'),
                "location": update_data.get('location'),
                "bio": update_data.get('bio'),
                "updatedAt": datetime.now()
            }
            # Remove None values
            consumer_update_data = {k: v for k, v in consumer_update_data.items() if v is not None}
            
            if consumer_update_data:
                consumer_ref.update(consumer_update_data)
                print(f"✅ Updated consumer document in consumers collection")
        
        # Get updated user data
        updated_doc = user_ref.get()
        updated_data = updated_doc.to_dict()
        
        return UserResponse(
            uid=current_user['uid'],
            email=current_user['email'],
            first_name=updated_data.get('first_name', ''),
            last_name=updated_data.get('last_name', ''),
            display_name=updated_data.get('display_name', ''),
            user_type=current_user['user_type'],
            phone=updated_data.get('phone'),
            location=updated_data.get('location'),
            bio=updated_data.get('bio'),
            join_date=current_user.get('join_date', datetime.now()),
            rating=updated_data.get('rating'),
            total_reviews=updated_data.get('total_reviews', 0),
            farmer_profile=updated_data.get('farmer_profile'),
            consumer_profile=updated_data.get('consumer_profile'),
            profile_image_url=updated_data.get('profile_image_url')
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update profile: {str(e)}"
        )

@router.put("/farmer", response_model=UserResponse)
async def update_farmer_profile(
    farmer_profile: FarmerProfile,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Update farmer-specific profile data"""
    try:
        # Check if user is a farmer
        if current_user.get('user_type') != 'farmer':
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only farmers can update farmer profile"
            )
        
        db = firestore.client()
        
        # Update farmer profile
        user_ref = db.collection('users').document(current_user['uid'])
        user_ref.update({
            'farmer_profile': farmer_profile.dict(),
            'updated_at': datetime.now()
        })
        
        # Get updated user data
        updated_doc = user_ref.get()
        updated_data = updated_doc.to_dict()
        
        return UserResponse(
            uid=current_user['uid'],
            email=current_user['email'],
            first_name=current_user.get('first_name', ''),
            last_name=current_user.get('last_name', ''),
            display_name=current_user.get('display_name', ''),
            user_type=current_user['user_type'],
            phone=current_user.get('phone'),
            location=current_user.get('location'),
            bio=current_user.get('bio'),
            join_date=current_user.get('join_date', datetime.now()),
            rating=current_user.get('rating'),
            total_reviews=current_user.get('total_reviews', 0),
            farmer_profile=updated_data.get('farmer_profile'),
            consumer_profile=current_user.get('consumer_profile')
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update farmer profile: {str(e)}"
        )

@router.put("/consumer", response_model=UserResponse)
async def update_consumer_profile(
    consumer_profile: ConsumerProfile,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Update consumer-specific profile data"""
    try:
        # Check if user is a consumer
        if current_user.get('user_type') != 'consumer':
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only consumers can update consumer profile"
            )
        
        db = firestore.client()
        
        # Update consumer profile
        user_ref = db.collection('users').document(current_user['uid'])
        user_ref.update({
            'consumer_profile': consumer_profile.dict(),
            'updated_at': datetime.now()
        })
        
        # Get updated user data
        updated_doc = user_ref.get()
        updated_data = updated_doc.to_dict()
        
        return UserResponse(
            uid=current_user['uid'],
            email=current_user['email'],
            first_name=current_user.get('first_name', ''),
            last_name=current_user.get('last_name', ''),
            display_name=current_user.get('display_name', ''),
            user_type=current_user['user_type'],
            phone=current_user.get('phone'),
            location=current_user.get('location'),
            bio=current_user.get('bio'),
            join_date=current_user.get('join_date', datetime.now()),
            rating=current_user.get('rating'),
            total_reviews=current_user.get('total_reviews', 0),
            farmer_profile=current_user.get('farmer_profile'),
            consumer_profile=updated_data.get('consumer_profile')
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update consumer profile: {str(e)}"
        )

@router.get("/{user_id}", response_model=UserResponse)
async def get_user_profile(
    user_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Get another user's public profile"""
    try:
        db = firestore.client()
        
        # Get user document
        user_doc = db.collection('users').document(user_id).get()
        
        if not user_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        user_data = user_doc.to_dict()
        
        return UserResponse(
            uid=user_id,
            email=user_data.get('email', ''),
            first_name=user_data.get('first_name', ''),
            last_name=user_data.get('last_name', ''),
            display_name=user_data.get('display_name', ''),
            user_type=user_data.get('user_type', 'consumer'),
            phone=user_data.get('phone'),
            location=user_data.get('location'),
            bio=user_data.get('bio'),
            join_date=user_data.get('join_date', datetime.now()),
            rating=user_data.get('rating'),
            total_reviews=user_data.get('total_reviews', 0),
            farmer_profile=user_data.get('farmer_profile'),
            consumer_profile=user_data.get('consumer_profile')
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch user profile: {str(e)}"
        )

@router.delete("/")
async def delete_account(current_user: Dict[str, Any] = Depends(get_current_user)):
    """Delete user account"""
    try:
        db = firestore.client()
        
        # Delete user's listings
        listings_query = db.collection('listings').where('farmer_id', '==', current_user['uid'])
        listings = listings_query.stream()
        for listing in listings:
            listing.reference.delete()
        
        # Delete user's predictions
        predictions_query = db.collection('crop_predictions_ai').where('user_id', '==', current_user['uid'])
        predictions = predictions_query.stream()
        for prediction in predictions:
            prediction.reference.delete()
        
        # Delete user document
        db.collection('users').document(current_user['uid']).delete()
        
        # Note: Firebase Auth user deletion should be handled on the client side
        # or through Firebase Admin SDK if needed
        
        return {"message": "Account deleted successfully"}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete account: {str(e)}"
        )

@router.post("/upload-image")
async def upload_profile_image(
    file: UploadFile = File(...),
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Upload profile image"""
    try:
        # Validate file type
        if not file.content_type.startswith('image/'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File must be an image"
            )
        
        # Read file data
        file_data = await file.read()
        
        # Upload to local storage
        image_url = await local_storage_service.upload_profile_image(
            current_user['uid'],
            file_data,
            file.content_type
        )
        
        if not image_url:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to upload image"
            )
        
        # Update user document with image URL
        db = firestore.client()
        user_ref = db.collection('users').document(current_user['uid'])
        user_ref.update({
            'profile_image_url': image_url,
            'updated_at': datetime.now()
        })
        
        return {
            "message": "Profile image uploaded successfully",
            "image_url": image_url
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to upload profile image: {str(e)}"
        )

@router.delete("/image")
async def delete_profile_image(
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Delete profile image"""
    try:
        db = firestore.client()
        user_ref = db.collection('users').document(current_user['uid'])
        
        # Get current user data
        user_doc = user_ref.get()
        if not user_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        user_data = user_doc.to_dict()
        current_image_url = user_data.get('profile_image_url')
        
        if current_image_url:
            # Delete from local storage
            await local_storage_service.delete_image(current_image_url)
        
        # Remove image URL from user document
        user_ref.update({
            'profile_image_url': None,
            'updated_at': datetime.now()
        })
        
        return {"message": "Profile image deleted successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete profile image: {str(e)}"
        )
