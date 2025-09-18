from fastapi import APIRouter, HTTPException, Depends, status, Query
from firebase_admin import firestore
from typing import Dict, Any, List, Optional
import uuid
from datetime import datetime

from models.listing import (
    ListingCreate, 
    ListingUpdate, 
    ListingResponse, 
    ListingSearchParams,
    ListingStatus,
    ListingStats
)
from auth_dependencies import get_current_user

router = APIRouter()

@router.get("/", response_model=List[ListingResponse])
async def get_listings(
    crop_type: Optional[str] = Query(None),
    location: Optional[str] = Query(None),
    price_min: Optional[float] = Query(None),
    price_max: Optional[float] = Query(None),
    is_organic: Optional[bool] = Query(None),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0)
):
    """Get marketplace listings with optional filters"""
    try:
        db = firestore.client()
        
        # Build query - simplified to avoid index requirements
        query = db.collection('listings').where('status', '==', 'active')
        
        # Apply pagination first (before ordering to avoid index requirement)
        query = query.limit(limit * 2)  # Get more results to filter later
        
        # Execute query
        listings = query.stream()
        
        result = []
        for listing in listings:
            listing_data = listing.to_dict()
            
            # Apply filters in memory (to avoid index requirements)
            if crop_type and listing_data.get('crop_name', '').lower() != crop_type.lower():
                continue
            if location and listing_data.get('location', '').lower() != location.lower():
                continue
            if is_organic is not None and listing_data.get('is_organic', False) != is_organic:
                continue
            
            # Apply price filter if specified
            if price_min is not None and listing_data.get('price', 0) < price_min:
                continue
            if price_max is not None and listing_data.get('price', 0) > price_max:
                continue
            
            result.append(ListingResponse(
                id=listing.id,
                cropName=listing_data.get('crop_name', ''),
                farmerId=listing_data.get('farmer_id', ''),
                farmerName=listing_data.get('farmer_name', ''),
                price=listing_data.get('price', 0),
                quantity=listing_data.get('quantity', 0),
                location=listing_data.get('location', ''),
                description=listing_data.get('description', ''),
                contact=listing_data.get('contact', ''),
                isOrganic=listing_data.get('is_organic', False),
                rating=listing_data.get('rating'),
                images=listing_data.get('images', []),
                status=ListingStatus(listing_data.get('status', 'active')),
                manufacturedDate=listing_data.get('manufactured_date'),
                createdAt=listing_data.get('created_at', datetime.now())
            ))
        
        # Sort by creation date (newest first) in memory
        result.sort(key=lambda x: x.createdAt, reverse=True)
        
        # Apply offset and limit
        return result[offset:offset + limit]
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch listings: {str(e)}"
        )

@router.post("/", response_model=ListingResponse)
async def create_listing(
    listing_data: ListingCreate,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Create a new marketplace listing"""
    try:
        # Check if user is a farmer
        if current_user.get('user_type') != 'farmer':
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only farmers can create listings"
            )
        
        db = firestore.client()
        
        # Generate listing ID
        listing_id = str(uuid.uuid4())
        
        # Prepare listing document
        listing_doc = {
            'crop_name': listing_data.crop_name,
            'farmer_id': current_user['uid'],
            'farmer_name': current_user.get('display_name', ''),
            'price': listing_data.price,
            'quantity': listing_data.quantity,
            'location': listing_data.location,
            'description': listing_data.description,
            'contact': listing_data.contact,
            'is_organic': listing_data.is_organic,
            'rating': None,
            'images': listing_data.images or [],
            'status': 'active',
            'manufactured_date': datetime.now(),
            'created_at': datetime.now(),
            'updated_at': datetime.now()
        }
        
        # Save to Firestore
        db.collection('listings').document(listing_id).set(listing_doc)
        
        # Update farmer's total listings count
        farmer_ref = db.collection('users').document(current_user['uid'])
        farmer_doc = farmer_ref.get()
        if farmer_doc.exists:
            farmer_data = farmer_doc.to_dict()
            if 'farmer_profile' in farmer_data:
                farmer_data['farmer_profile']['total_listings'] += 1
                farmer_ref.update({'farmer_profile': farmer_data['farmer_profile']})
        
        return ListingResponse(
            id=listing_id,
            **listing_doc
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create listing: {str(e)}"
        )

@router.get("/{listing_id}", response_model=ListingResponse)
async def get_listing_by_id(listing_id: str):
    """Get specific listing by ID"""
    try:
        db = firestore.client()
        
        listing_doc = db.collection('listings').document(listing_id).get()
        
        if not listing_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Listing not found"
            )
        
        listing_data = listing_doc.to_dict()
        
        return ListingResponse(
            id=listing_doc.id,
            cropName=listing_data.get('crop_name', ''),
            farmerId=listing_data.get('farmer_id', ''),
            farmerName=listing_data.get('farmer_name', ''),
            price=listing_data.get('price', 0),
            quantity=listing_data.get('quantity', 0),
            location=listing_data.get('location', ''),
            description=listing_data.get('description', ''),
            contact=listing_data.get('contact', ''),
            isOrganic=listing_data.get('is_organic', False),
            rating=listing_data.get('rating'),
            images=listing_data.get('images', []),
            status=ListingStatus(listing_data.get('status', 'active')),
            manufacturedDate=listing_data.get('manufactured_date'),
            createdAt=listing_data.get('created_at', datetime.now())
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch listing: {str(e)}"
        )

@router.put("/{listing_id}", response_model=ListingResponse)
async def update_listing(
    listing_id: str,
    listing_update: ListingUpdate,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Update a listing"""
    try:
        db = firestore.client()
        
        # Get existing listing
        listing_ref = db.collection('listings').document(listing_id)
        listing_doc = listing_ref.get()
        
        if not listing_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Listing not found"
            )
        
        listing_data = listing_doc.to_dict()
        
        # Check if user owns this listing
        if listing_data.get('farmer_id') != current_user['uid']:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only update your own listings"
            )
        
        # Prepare update data
        update_data = {}
        for field, value in listing_update.dict(exclude_unset=True).items():
            if value is not None:
                update_data[field] = value
        
        update_data['updated_at'] = datetime.now()
        
        # Update listing
        listing_ref.update(update_data)
        
        # Get updated listing
        updated_doc = listing_ref.get()
        updated_data = updated_doc.to_dict()
        
        return ListingResponse(
            id=updated_doc.id,
            crop_name=updated_data.get('crop_name', ''),
            farmer_id=updated_data.get('farmer_id', ''),
            farmer_name=updated_data.get('farmer_name', ''),
            price=updated_data.get('price', 0),
            quantity=updated_data.get('quantity', 0),
            location=updated_data.get('location', ''),
            description=updated_data.get('description', ''),
            contact=updated_data.get('contact', ''),
            is_organic=updated_data.get('is_organic', False),
            rating=updated_data.get('rating'),
            images=updated_data.get('images', []),
            status=ListingStatus(updated_data.get('status', 'active')),
            manufactured_date=updated_data.get('manufactured_date'),
            created_at=updated_data.get('created_at', datetime.now())
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update listing: {str(e)}"
        )

@router.delete("/{listing_id}")
async def delete_listing(
    listing_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Delete a listing"""
    try:
        db = firestore.client()
        
        # Get existing listing
        listing_ref = db.collection('listings').document(listing_id)
        listing_doc = listing_ref.get()
        
        if not listing_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Listing not found"
            )
        
        listing_data = listing_doc.to_dict()
        
        # Check if user owns this listing
        if listing_data.get('farmer_id') != current_user['uid']:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only delete your own listings"
            )
        
        # Delete listing
        listing_ref.delete()
        
        # Update farmer's total listings count
        farmer_ref = db.collection('users').document(current_user['uid'])
        farmer_doc = farmer_ref.get()
        if farmer_doc.exists:
            farmer_data = farmer_doc.to_dict()
            if 'farmer_profile' in farmer_data:
                farmer_data['farmer_profile']['total_listings'] = max(0, farmer_data['farmer_profile']['total_listings'] - 1)
                farmer_ref.update({'farmer_profile': farmer_data['farmer_profile']})
        
        return {"message": "Listing deleted successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete listing: {str(e)}"
        )

@router.get("/farmer/{farmer_id}", response_model=List[ListingResponse])
async def get_farmer_listings(
    farmer_id: str,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0)
):
    """Get all listings by a specific farmer"""
    try:
        db = firestore.client()
        
        query = (
            db.collection('listings')
            .where('farmer_id', '==', farmer_id)
            .order_by('created_at', direction=firestore.Query.DESCENDING)
            .limit(limit)
            .offset(offset)
        )
        
        listings = query.stream()
        
        result = []
        for listing in listings:
            listing_data = listing.to_dict()
            result.append(ListingResponse(
                id=listing.id,
                cropName=listing_data.get('crop_name', ''),
                farmerId=listing_data.get('farmer_id', ''),
                farmerName=listing_data.get('farmer_name', ''),
                price=listing_data.get('price', 0),
                quantity=listing_data.get('quantity', 0),
                location=listing_data.get('location', ''),
                description=listing_data.get('description', ''),
                contact=listing_data.get('contact', ''),
                isOrganic=listing_data.get('is_organic', False),
                rating=listing_data.get('rating'),
                images=listing_data.get('images', []),
                status=ListingStatus(listing_data.get('status', 'active')),
                manufacturedDate=listing_data.get('manufactured_date'),
                createdAt=listing_data.get('created_at', datetime.now())
            ))
        
        return result
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch farmer listings: {str(e)}"
        )

@router.get("/stats/overview", response_model=ListingStats)
async def get_listing_stats():
    """Get marketplace statistics"""
    try:
        db = firestore.client()
        
        # Get total listings
        total_listings = len(list(db.collection('listings').stream()))
        
        # Get active listings
        active_listings = len(list(db.collection('listings').where('status', '==', 'active').stream()))
        
        # Calculate average rating
        listings_with_rating = list(db.collection('listings').where('rating', '>', 0).stream())
        if listings_with_rating:
            total_rating = sum(doc.to_dict().get('rating', 0) for doc in listings_with_rating)
            average_rating = total_rating / len(listings_with_rating)
        else:
            average_rating = 0.0
        
        # Get total sales (mock calculation)
        total_sales = len(list(db.collection('listings').where('status', '==', 'sold').stream()))
        
        return ListingStats(
            total_listings=total_listings,
            active_listings=active_listings,
            total_sales=total_sales,
            average_rating=round(average_rating, 2)
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch listing stats: {str(e)}"
        )
