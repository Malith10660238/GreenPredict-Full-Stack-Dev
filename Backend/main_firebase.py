"""
Complete Firebase-integrated backend for GreenPredict
Stores all user data, marketplace listings, and interactions in Firebase
"""
from fastapi import FastAPI, HTTPException, Depends, status, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import firebase_admin
from firebase_admin import credentials, firestore, auth
import uvicorn
import json
import os
from datetime import datetime
from typing import Optional, List
import uuid

# Import routers
from routers.prediction_router import router as prediction_router
from ai_model_service import ai_service

# Initialize FastAPI app
app = FastAPI(
    title="GreenPredict Backend API (Firebase)",
    description="Complete Firebase-integrated backend for GreenPredict",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Firebase Admin SDK
def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    if not firebase_admin._apps:
        try:
            service_account_path = "serviceAccountKey.json"
            if os.path.exists(service_account_path):
                cred = credentials.Certificate(service_account_path)
                firebase_admin.initialize_app(cred)
            else:
                firebase_admin.initialize_app()
        except Exception as e:
            print(f"Warning: Firebase initialization failed: {e}")
            return None
    return firestore.client()

# Initialize Firebase
db = initialize_firebase()

# Initialize AI service
print("🤖 Initializing AI Model Service...")
ai_service_loaded = ai_service.load_models()
if ai_service_loaded:
    print("✅ AI Model Service initialized successfully")
else:
    print("❌ Failed to initialize AI Model Service")

# Authentication
security = HTTPBearer()

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Get current authenticated user"""
    try:
        # Try to verify as ID token first
        try:
            decoded_token = auth.verify_id_token(credentials.credentials)
            uid = decoded_token['uid']
        except:
            # If ID token verification fails, try to verify as custom token
            try:
                import jwt
                decoded_token = jwt.decode(credentials.credentials, options={"verify_signature": False})
                uid = decoded_token.get('uid')
                if not uid:
                    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token format")
            except:
                raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token format")
        
        # Get user data from Firestore
        user_doc = db.collection('users').document(uid).get()
        if user_doc.exists:
            user_data = user_doc.to_dict()
            user_data['uid'] = uid
            
            # Also get type-specific data from farmers/consumers collections
            user_type = user_data.get('userType', '')
            if user_type == 'farmer':
                farmer_doc = db.collection('farmers').document(uid).get()
                if farmer_doc.exists:
                    farmer_data = farmer_doc.to_dict()
                    # Merge farmer-specific data
                    user_data['farmerProfile'] = {
                        'farmName': farmer_data.get('farmName'),
                        'farmSize': farmer_data.get('farmSize'),
                        'crops': farmer_data.get('crops', []),
                        'farmingExperience': farmer_data.get('farmingExperience'),
                        'totalListings': farmer_data.get('totalListings'),
                        'totalSales': farmer_data.get('totalSales'),
                        'certification': farmer_data.get('certification')
                    }
            elif user_type == 'consumer':
                consumer_doc = db.collection('consumers').document(uid).get()
                if consumer_doc.exists:
                    consumer_data = consumer_doc.to_dict()
                    # Merge consumer-specific data
                    user_data['consumerProfile'] = {
                        'preferences': consumer_data.get('preferences', []),
                        'totalOrders': consumer_data.get('totalOrders'),
                        'totalSpent': consumer_data.get('totalSpent'),
                        'favoriteCrops': consumer_data.get('favoriteCrops', []),
                        'deliveryAddress': consumer_data.get('deliveryAddress'),
                        'paymentMethod': consumer_data.get('paymentMethod')
                    }
            
            return user_data
        else:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Welcome to GreenPredict Backend API (Firebase)",
        "version": "1.0.0",
        "status": "running"
    }

@app.get("/ping")
async def ping():
    """Lightweight ping endpoint"""
    return {"pong": True}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "GreenPredict Backend (Firebase)"}

# Include routers
app.include_router(prediction_router, prefix="/predictions", tags=["predictions"])

# ==================== AUTHENTICATION ENDPOINTS ====================

@app.post("/auth/register")
async def register(register_data: dict):
    """User registration with Firebase Auth and Firestore storage"""
    try:
        email = register_data.get("email")
        password = register_data.get("password")
        firstName = register_data.get("firstName", "New")
        lastName = register_data.get("lastName", "User")
        userType = register_data.get("userType", "farmer")
        phone = register_data.get("phone", "")
        location = register_data.get("location", "")
        bio = register_data.get("bio", "")
        
        if not email or not password:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email and password are required"
            )
        
        # Create user in Firebase Auth
        user = auth.create_user(
            email=email,
            password=password,
            display_name=f"{firstName} {lastName}"
        )
        
        # Hash password for storage
        import hashlib
        password_hash = hashlib.sha256(password.encode()).hexdigest()
        
        # Prepare user data for Firestore
        user_data = {
            "email": email,
            "password": password_hash,
            "firstName": firstName,
            "lastName": lastName,
            "displayName": f"{firstName} {lastName}",
            "userType": userType,
            "phone": phone,
            "location": location,
            "bio": bio,
            "joinDate": datetime.now(),
            "rating": None,
            "totalReviews": 0,
            "createdAt": datetime.now(),
            "updatedAt": datetime.now()
        }
        
        # Add user-specific profile data
        if userType == "farmer":
            user_data["farmerProfile"] = {
                "farmName": register_data.get("farmName", ""),
                "farmSize": register_data.get("farmSize", ""),
                "crops": [],
                "farmingExperience": register_data.get("farmingExperience", ""),
                "totalListings": 0,
                "totalSales": 0,
                "certification": register_data.get("certification", "")
            }
        else:
            user_data["consumerProfile"] = {
                "preferences": [],
                "totalOrders": 0,
                "totalSpent": 0.0,
                "favoriteCrops": []
            }
        
        # Save user data to Firestore
        db.collection('users').document(user.uid).set(user_data)
        
        # Also create document in type-specific collection
        if userType == 'farmer':
            farmer_data = {
                "uid": user.uid,
                "email": email,
                "firstName": firstName,
                "lastName": lastName,
                "displayName": f"{firstName} {lastName}",
                "phone": phone,
                "location": location,
                "bio": bio,
                "joinDate": datetime.now(),
                "rating": 0.0,
                "totalReviews": 0,
                "farmName": "",
                "farmSize": "",
                "crops": [],
                "farmingExperience": "",
                "totalListings": 0,
                "totalSales": 0,
                "certification": "",
                "profileImageUrl": None,
                "createdAt": datetime.now(),
                "updatedAt": datetime.now()
            }
            db.collection('farmers').document(user.uid).set(farmer_data)
        elif userType == 'consumer':
            consumer_data = {
                "uid": user.uid,
                "email": email,
                "firstName": firstName,
                "lastName": lastName,
                "displayName": f"{firstName} {lastName}",
                "phone": phone,
                "location": location,
                "bio": bio,
                "joinDate": datetime.now(),
                "rating": 0.0,
                "totalReviews": 0,
                "preferences": [],
                "totalOrders": 0,
                "totalSpent": 0.0,
                "favoriteCrops": [],
                "deliveryAddress": "",
                "paymentMethod": "",
                "profileImageUrl": None,
                "createdAt": datetime.now(),
                "updatedAt": datetime.now()
            }
            db.collection('consumers').document(user.uid).set(consumer_data)
        
        # Create custom token for immediate login
        custom_token = auth.create_custom_token(user.uid)
        
        return {
            "message": "User registered successfully",
            "access_token": custom_token.decode('utf-8'),
            "user": {
                "uid": user.uid,
                "email": email,
                "firstName": firstName,
                "lastName": lastName,
                "displayName": f"{firstName} {lastName}",
                "userType": userType
            }
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Registration failed: {str(e)}"
        )

@app.post("/auth/login")
async def login(login_data: dict):
    """User login with password verification"""
    try:
        email = login_data.get("email")
        password = login_data.get("password")
        
        if not email or not password:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email and password are required"
            )
        
        # Find user by email in Firestore
        users_ref = db.collection('users')
        query = users_ref.where('email', '==', email).limit(1)
        docs = query.stream()
        
        user_doc = None
        for doc in docs:
            user_doc = doc
            break
        
        if not user_doc:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
        
        # Verify password
        user_data = user_doc.to_dict()
        stored_password_hash = user_data.get('password')
        
        if not stored_password_hash:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
        
        # Hash the provided password and compare
        import hashlib
        provided_password_hash = hashlib.sha256(password.encode()).hexdigest()
        
        if provided_password_hash != stored_password_hash:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
        
        user_data['uid'] = user_doc.id
        
        # Create custom token
        custom_token = auth.create_custom_token(user_doc.id)
        
        # Get type-specific profile data
        user_type = user_data.get("userType", "")
        if user_type == "farmer":
            farmer_doc = db.collection('farmers').document(user_doc.id).get()
            if farmer_doc.exists:
                farmer_data = farmer_doc.to_dict()
                user_data['farmerProfile'] = {
                    'farmName': farmer_data.get('farmName'),
                    'farmSize': farmer_data.get('farmSize'),
                    'crops': farmer_data.get('crops', []),
                    'farmingExperience': farmer_data.get('farmingExperience'),
                    'totalListings': farmer_data.get('totalListings'),
                    'totalSales': farmer_data.get('totalSales'),
                    'certification': farmer_data.get('certification')
                }
        elif user_type == "consumer":
            consumer_doc = db.collection('consumers').document(user_doc.id).get()
            if consumer_doc.exists:
                consumer_data = consumer_doc.to_dict()
                user_data['consumerProfile'] = {
                    'preferences': consumer_data.get('preferences', []),
                    'totalOrders': consumer_data.get('totalOrders'),
                    'totalSpent': consumer_data.get('totalSpent'),
                    'favoriteCrops': consumer_data.get('favoriteCrops', []),
                    'deliveryAddress': consumer_data.get('deliveryAddress'),
                    'paymentMethod': consumer_data.get('paymentMethod')
                }
        
        return {
            "access_token": custom_token.decode('utf-8'),
            "user": user_data
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Login failed: {str(e)}"
        )

# ==================== USER PROFILE ENDPOINTS ====================

@app.get("/profile/")
async def get_profile(current_user: dict = Depends(get_current_user)):
    """Get user profile from Firebase"""
    return current_user

@app.put("/profile/")
async def update_profile(profile_data: dict, current_user: dict = Depends(get_current_user)):
    """Update user profile in Firebase"""
    try:
        uid = current_user['uid']
        
        # Update user data
        update_data = {
            "updatedAt": datetime.now()
        }
        
        # Update basic fields
        for field in ["firstName", "lastName", "phone", "location", "bio"]:
            if field in profile_data:
                update_data[field] = profile_data[field]
        
        # Update display name if first/last name changed
        if "firstName" in profile_data or "lastName" in profile_data:
            firstName = profile_data.get("firstName", current_user.get("firstName", ""))
            lastName = profile_data.get("lastName", current_user.get("lastName", ""))
            update_data["displayName"] = f"{firstName} {lastName}"
        
        # Update user-specific profiles
        user_type = current_user.get("userType", "farmer")
        if user_type == "farmer":
            farmer_profile = current_user.get("farmerProfile", {})
            for field in ["farmName", "farmSize", "farmingExperience", "certification"]:
                if field in profile_data:
                    farmer_profile[field] = profile_data[field]
            update_data["farmerProfile"] = farmer_profile
        else:
            consumer_profile = current_user.get("consumerProfile", {})
            if "preferences" in profile_data:
                consumer_profile["preferences"] = profile_data["preferences"]
            update_data["consumerProfile"] = consumer_profile
        
        # Update in Firestore - users collection
        db.collection('users').document(uid).update(update_data)
        print(f"✅ Updated user document in users collection")
        
        # Also update the type-specific collection (farmers or consumers)
        user_type = current_user.get("userType", "farmer")
        if user_type == "farmer":
            # Update farmers collection
            farmer_update_data = {
                "firstName": update_data.get("firstName"),
                "lastName": update_data.get("lastName"),
                "displayName": update_data.get("displayName"),
                "phone": update_data.get("phone"),
                "location": update_data.get("location"),
                "bio": update_data.get("bio"),
                "updatedAt": update_data.get("updatedAt")
            }
            # Remove None values
            farmer_update_data = {k: v for k, v in farmer_update_data.items() if v is not None}
            
            if farmer_update_data:
                db.collection('farmers').document(uid).update(farmer_update_data)
                print(f"✅ Updated farmer document in farmers collection")
                
        elif user_type == "consumer":
            # Update consumers collection
            consumer_update_data = {
                "firstName": update_data.get("firstName"),
                "lastName": update_data.get("lastName"),
                "displayName": update_data.get("displayName"),
                "phone": update_data.get("phone"),
                "location": update_data.get("location"),
                "bio": update_data.get("bio"),
                "updatedAt": update_data.get("updatedAt")
            }
            # Remove None values
            consumer_update_data = {k: v for k, v in consumer_update_data.items() if v is not None}
            
            if consumer_update_data:
                db.collection('consumers').document(uid).update(consumer_update_data)
                print(f"✅ Updated consumer document in consumers collection")
        
        # Get updated user data
        updated_doc = db.collection('users').document(uid).get()
        updated_user = updated_doc.to_dict()
        updated_user['uid'] = uid
        
        return {
            "message": "Profile updated successfully",
            "user": updated_user
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Profile update failed: {str(e)}"
        )

# ==================== MARKETPLACE LISTINGS ENDPOINTS ====================

@app.get("/listings/")
async def get_listings(
    crop_type: Optional[str] = Query(None),
    location: Optional[str] = Query(None),
    price_min: Optional[float] = Query(None),
    price_max: Optional[float] = Query(None),
    is_organic: Optional[bool] = Query(None),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0)
):
    """Get marketplace listings from Firebase"""
    try:
        listings_ref = db.collection('listings')
        query = listings_ref.where('status', '==', 'active').limit(limit).offset(offset)
        
        # Apply filters
        if crop_type:
            query = query.where('cropName', '==', crop_type)
        if location:
            query = query.where('location', '==', location)
        if is_organic is not None:
            query = query.where('isOrganic', '==', is_organic)
        
        listings = []
        for doc in query.stream():
            listing_data = doc.to_dict()
            listing_data['id'] = doc.id
            listings.append(listing_data)
        
        return {
            "listings": listings,
            "total": len(listings),
            "limit": limit,
            "offset": offset
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch listings: {str(e)}"
        )

@app.post("/listings/")
async def create_listing(listing_data: dict, current_user: dict = Depends(get_current_user)):
    """Create a new marketplace listing in Firebase"""
    try:
        if current_user.get("userType") != "farmer":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only farmers can create listings"
            )
        
        # Generate unique listing ID
        listing_id = str(uuid.uuid4())
        
        # Handle manufactured date
        manufactured_date = listing_data.get("manufacturedDate") or listing_data.get("manufactured_date")
        print(f"🔍 Received manufactured_date: {manufactured_date} (type: {type(manufactured_date)})")
        
        if manufactured_date:
            try:
                # Parse the date from frontend
                if isinstance(manufactured_date, str):
                    # Handle different date formats
                    if '/' in manufactured_date:
                        # Format: "15/9/2025"
                        day, month, year = manufactured_date.split('/')
                        manufactured_date = datetime(int(year), int(month), int(day))
                        print(f"✅ Parsed date from DD/MM/YYYY format: {manufactured_date}")
                    elif 'T' in manufactured_date:
                        # ISO format from frontend: "2025-09-17T12:00:00.000Z" or "2025-09-17T12:00:00.000"
                        if manufactured_date.endswith('Z'):
                            manufactured_date = datetime.fromisoformat(manufactured_date.replace('Z', '+00:00'))
                        else:
                            # Handle format without Z: "2025-09-13T00:00:00.000"
                            manufactured_date = datetime.fromisoformat(manufactured_date)
                        print(f"✅ Parsed date from ISO format: {manufactured_date}")
                    else:
                        # Try to parse as ISO format
                        if manufactured_date.endswith('Z'):
                            manufactured_date = datetime.fromisoformat(manufactured_date.replace('Z', '+00:00'))
                        else:
                            manufactured_date = datetime.fromisoformat(manufactured_date)
                        print(f"✅ Parsed date from ISO format (fallback): {manufactured_date}")
                else:
                    print(f"⚠️ Warning: manufactured_date is not a string: {type(manufactured_date)}")
                    manufactured_date = datetime.now()
            except Exception as e:
                print(f"❌ Error: Could not parse manufactured_date '{manufactured_date}': {e}")
                manufactured_date = datetime.now()
        else:
            # If no manufactured date provided, use current date
            print(f"⚠️ Warning: No manufactured_date provided, using current date")
            manufactured_date = datetime.now()
        
        print(f"🔍 Final manufactured_date: {manufactured_date}")
        
        # Prepare listing data
        listing = {
            "id": listing_id,
            "cropName": listing_data.get("cropName"),
            "price": float(listing_data.get("price", 0)),
            "quantity": int(listing_data.get("quantity", 0)),
            "location": listing_data.get("location"),
            "description": listing_data.get("description"),
            "contact": listing_data.get("contact"),
            "isOrganic": listing_data.get("isOrganic", False),
            "farmerId": current_user["uid"],
            "farmerName": current_user.get("displayName", ""),
            "rating": None,
            "images": listing_data.get("images", []),
            "status": "active",
            "manufacturedDate": manufactured_date,
            "createdAt": datetime.now(),
            "updatedAt": datetime.now()
        }
        
        # Save to Firebase
        db.collection('listings').document(listing_id).set(listing)
        
        # Update farmer's total listings count
        farmer_ref = db.collection('users').document(current_user["uid"])
        farmer_doc = farmer_ref.get()
        if farmer_doc.exists:
            farmer_data = farmer_doc.to_dict()
            farmer_profile = farmer_data.get("farmerProfile", {})
            farmer_profile["totalListings"] = farmer_profile.get("totalListings", 0) + 1
            farmer_ref.update({
                "farmerProfile": farmer_profile,
                "updatedAt": datetime.now()
            })
        
        return {
            "message": "Listing created successfully",
            "listing": listing
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create listing: {str(e)}"
        )

@app.get("/listings/my")
async def get_my_listings(current_user: dict = Depends(get_current_user)):
    """Get current user's listings from Firebase"""
    try:
        if current_user.get("userType") != "farmer":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only farmers can view their listings"
            )
        
        listings_ref = db.collection('listings')
        query = listings_ref.where('farmerId', '==', current_user["uid"])
        
        listings = []
        for doc in query.stream():
            listing_data = doc.to_dict()
            listing_data['id'] = doc.id
            listings.append(listing_data)
        
        return {
            "listings": listings,
            "total": len(listings)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch user listings: {str(e)}"
        )

@app.put("/listings/{listing_id}")
async def update_listing(listing_id: str, listing_data: dict, current_user: dict = Depends(get_current_user)):
    """Update a listing in Firebase"""
    try:
        # Check if listing exists and belongs to user
        listing_ref = db.collection('listings').document(listing_id)
        listing_doc = listing_ref.get()
        
        if not listing_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Listing not found"
            )
        
        listing = listing_doc.to_dict()
        if listing.get("farmerId") != current_user["uid"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only update your own listings"
            )
        
        # Update listing data
        update_data = {
            "updatedAt": datetime.now()
        }
        
        for field in ["cropName", "price", "quantity", "location", "description", "contact", "isOrganic", "images", "status"]:
            if field in listing_data:
                update_data[field] = listing_data[field]
                if field == "images":
                    print(f"🔍 Updating images: {listing_data[field]}")
        
        listing_ref.update(update_data)
        
        # Get updated listing
        updated_doc = listing_ref.get()
        updated_listing = updated_doc.to_dict()
        updated_listing['id'] = listing_id
        
        return {
            "message": "Listing updated successfully",
            "listing": updated_listing
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update listing: {str(e)}"
        )

@app.delete("/listings/{listing_id}")
async def delete_listing(listing_id: str, current_user: dict = Depends(get_current_user)):
    """Delete a listing from Firebase"""
    try:
        # Check if listing exists and belongs to user
        listing_ref = db.collection('listings').document(listing_id)
        listing_doc = listing_ref.get()
        
        if not listing_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Listing not found"
            )
        
        listing = listing_doc.to_dict()
        if listing.get("farmerId") != current_user["uid"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only delete your own listings"
            )
        
        # Delete listing
        listing_ref.delete()
        
        # Update farmer's total listings count
        farmer_ref = db.collection('users').document(current_user["uid"])
        farmer_doc = farmer_ref.get()
        if farmer_doc.exists:
            farmer_data = farmer_doc.to_dict()
            farmer_profile = farmer_data.get("farmerProfile", {})
            farmer_profile["totalListings"] = max(0, farmer_profile.get("totalListings", 0) - 1)
            farmer_ref.update({
                "farmerProfile": farmer_profile,
                "updatedAt": datetime.now()
            })
        
        return {
            "message": "Listing deleted successfully"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete listing: {str(e)}"
        )

if __name__ == "__main__":
    uvicorn.run(
        "main_firebase:app",
        host="0.0.0.0",
        port=8001,
        reload=True
    )
