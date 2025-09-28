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
                    # Merge farmer-specific data - use top-level fields (not nested farmerProfile)
                    user_data['farmerProfile'] = {
                        'farmName': farmer_data.get('farmName'),
                        'farmSize': farmer_data.get('farmSize'),
                        'crops': farmer_data.get('crops', []),  # Use top-level crops field
                        'farmingExperience': farmer_data.get('farmingExperience'),
                        'totalListings': farmer_data.get('totalListings'),
                        'totalSales': farmer_data.get('totalSales'),
                        'certification': farmer_data.get('certification')
                    }
                    print(f"🔍 Farmer data from farmers collection: {farmer_data}")
                    print(f"🔍 Crops from farmers collection: {farmer_data.get('crops', [])}")
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

@app.get("/", tags=["Core"])
async def root():
    """Root endpoint"""
    return {
        "message": "Welcome to GreenPredict Backend API (Firebase)",
        "version": "1.0.0",
        "status": "running"
    }

@app.get("/ping", tags=["Core"])
async def ping():
    """Lightweight ping endpoint"""
    return {"pong": True}

@app.get("/health", tags=["Core"])
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "GreenPredict Backend (Firebase)"}

# Include routers
app.include_router(prediction_router, prefix="/predictions", tags=["predictions"])

# ==================== AUTHENTICATION ENDPOINTS ====================

@app.post("/auth/register", tags=["Authentication"])
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

@app.post("/auth/login", tags=["Authentication"])
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

@app.get("/profile/", tags=["User Profiles"])
async def get_profile(current_user: dict = Depends(get_current_user)):
    """Get user profile from Firebase"""
    return current_user

@app.put("/profile/", tags=["User Profiles"])
async def update_profile(profile_data: dict, current_user: dict = Depends(get_current_user)):
    """Update user profile in Firebase"""
    try:
        print(f"🔍 Profile update request from user: {current_user.get('displayName', 'Unknown')}")
        print(f"📝 Profile update data: {profile_data}")
        print(f"🔍 Profile data keys: {list(profile_data.keys())}")
        if 'consumerProfile' in profile_data:
            print(f"🔍 Consumer profile data: {profile_data['consumerProfile']}")
            if 'preferences' in profile_data['consumerProfile']:
                print(f"🔍 Preferences being sent: {profile_data['consumerProfile']['preferences']}")
        if 'farmerProfile' in profile_data:
            print(f"🔍 Farmer profile data: {profile_data['farmerProfile']}")
            if 'crops' in profile_data['farmerProfile']:
                print(f"🔍 Crops being sent: {profile_data['farmerProfile']['crops']}")
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
        print(f"🔍 User type: {user_type}")
        if user_type == "farmer":
            farmer_profile = current_user.get("farmerProfile", {})
            # Check if farmerProfile is in the request data
            if "farmerProfile" in profile_data:
                print(f"🔍 Processing farmerProfile from request: {profile_data['farmerProfile']}")
                # Update farmer profile with data from request
                for field in ["farmName", "farmSize", "farmingExperience", "certification", "crops"]:
                    if field in profile_data["farmerProfile"]:
                        farmer_profile[field] = profile_data["farmerProfile"][field]
                        print(f"🔍 Updated farmer field {field}: {profile_data['farmerProfile'][field]}")
            update_data["farmerProfile"] = farmer_profile
        else:
            consumer_profile = current_user.get("consumerProfile", {})
            print(f"🔍 Current consumer profile: {consumer_profile}")
            if "consumerProfile" in profile_data:
                print(f"🔍 Updating consumer profile with: {profile_data['consumerProfile']}")
                # Replace the entire consumer profile, don't merge
                consumer_profile = profile_data["consumerProfile"]
            update_data["consumerProfile"] = consumer_profile
            print(f"🔍 Final consumer profile: {consumer_profile}")
        
        # Update in Firestore - users collection
        print(f"🔍 About to update users collection with: {update_data}")
        db.collection('users').document(uid).update(update_data)
        print(f"✅ Updated user document in users collection")
        
        # Verify the update by reading back the document
        updated_doc = db.collection('users').document(uid).get()
        updated_data = updated_doc.to_dict()
        print(f"🔍 Verification - Updated document consumerProfile: {updated_data.get('consumerProfile', {})}")
        
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
            
            # Update crops field directly in farmers collection
            print(f"🔍 Checking for farmerProfile in update_data: {'farmerProfile' in update_data}")
            if "farmerProfile" in update_data:
                print(f"🔍 farmerProfile content: {update_data['farmerProfile']}")
                print(f"🔍 Checking for crops in farmerProfile: {'crops' in update_data['farmerProfile']}")
                if "crops" in update_data["farmerProfile"]:
                    crops = update_data["farmerProfile"]["crops"]
                    farmer_update_data["crops"] = crops
                    print(f"🔍 Adding crops to farmers collection: {crops}")
                else:
                    print("🔍 No crops field found in farmerProfile")
            else:
                print("🔍 No farmerProfile found in update_data")
            # Remove None values
            farmer_update_data = {k: v for k, v in farmer_update_data.items() if v is not None}
            
            if farmer_update_data:
                db.collection('farmers').document(uid).update(farmer_update_data)
                print(f"✅ Updated farmer document in farmers collection")
                
                # Verify the update by reading back the document
                updated_farmer_doc = db.collection('farmers').document(uid).get()
                updated_farmer_data = updated_farmer_doc.to_dict()
                print(f"🔍 Verification - Updated farmer crops: {updated_farmer_data.get('crops', [])}")
                
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
            
            # Also update consumer profile data (including preferences)
            if "consumerProfile" in update_data:
                consumer_update_data["consumerProfile"] = update_data["consumerProfile"]
                print(f"🔍 Adding consumerProfile to consumers collection: {update_data['consumerProfile']}")
            
            # Remove None values
            consumer_update_data = {k: v for k, v in consumer_update_data.items() if v is not None}
            print(f"🔍 Final consumer update data: {consumer_update_data}")
            
            if consumer_update_data:
                db.collection('consumers').document(uid).update(consumer_update_data)
                print(f"✅ Updated consumer document in consumers collection")
        
        # Get updated user data
        updated_doc = db.collection('users').document(uid).get()
        updated_user = updated_doc.to_dict()
        updated_user['uid'] = uid
        
        # Also get updated farmer data if user is farmer
        if user_type == "farmer":
            farmer_doc = db.collection('farmers').document(uid).get()
            if farmer_doc.exists:
                farmer_data = farmer_doc.to_dict()
                # Get existing farmerProfile from users collection and update crops
                existing_farmer_profile = updated_user.get('farmerProfile', {})
                existing_farmer_profile['crops'] = farmer_data.get('crops', [])
                updated_user['farmerProfile'] = existing_farmer_profile
                print(f"🔍 Response - Updated crops: {farmer_data.get('crops', [])}")
        
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

@app.get("/listings/", tags=["Marketplace"])
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

@app.post("/listings/", tags=["Marketplace"])
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
            "category": listing_data.get("category", "Vegetables"),  # Add category field with default
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

@app.get("/listings/my", tags=["Marketplace"])
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

@app.put("/listings/{listing_id}", tags=["Marketplace"])
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
        
        for field in ["cropName", "category", "price", "quantity", "location", "description", "contact", "isOrganic", "images", "status"]:
            if field in listing_data:
                update_data[field] = listing_data[field]
                if field == "images":
                    print(f"🔍 Updating images: {listing_data[field]}")
                if field == "category":
                    print(f"🔍 Updating category: {listing_data[field]}")
        
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

@app.delete("/listings/{listing_id}", tags=["Marketplace"])
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

# ==================== INQUIRY ENDPOINTS ====================

@app.get("/test-inquiries", tags=["Inquiries"])
async def test_inquiries():
    """Test endpoint to verify server is working"""
    return {"message": "Inquiry endpoints are available", "status": "working"}

@app.post("/test-create-inquiry", tags=["Inquiries"])
async def test_create_inquiry(inquiry_data: dict, current_user: dict = Depends(get_current_user)):
    """Test endpoint to create inquiry"""
    print(f"🔵 TEST Inquiry endpoint hit! Data: {inquiry_data}")
    print(f"🔵 TEST Current user: {current_user}")
    return {"message": "Test inquiry created", "id": "test_123"}

@app.post("/api/inquiries", tags=["Inquiries"])
async def create_inquiry(inquiry_data: dict, current_user: dict = Depends(get_current_user)):
    """Create a new inquiry from consumer to farmer"""
    print(f"🔵 Inquiry endpoint hit! Data: {inquiry_data}")
    print(f"🔵 Current user: {current_user}")
    try:
        farmer_id = inquiry_data.get("farmerId")
        product_id = inquiry_data.get("productId")
        message = inquiry_data.get("message")
        
        if not farmer_id or not product_id or not message:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Missing required fields: farmerId, productId, message"
            )
        
        # Get product details from listings collection
        product_ref = db.collection("listings").document(product_id)
        product_doc = product_ref.get()
        
        if not product_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found"
            )
        
        product_data = product_doc.to_dict()
        
        # Get farmer details
        farmer_ref = db.collection("farmers").document(farmer_id)
        farmer_doc = farmer_ref.get()
        
        if not farmer_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Farmer not found"
            )
        
        farmer_data = farmer_doc.to_dict()
        
        # Create inquiry document
        inquiry_data = {
            "consumerId": current_user["uid"],
            "farmerId": farmer_id,
            "productId": product_id,
            "productName": product_data.get("name", "Unknown Product"),
            "farmerName": farmer_data.get("firstName", "") + " " + farmer_data.get("lastName", ""),
            "consumerName": current_user.get("displayName", "Consumer"),
            "status": "pending",
            "createdAt": datetime.now(),
            "updatedAt": datetime.now(),
            "messages": [{
                "senderId": current_user["uid"],
                "message": message,
                "timestamp": datetime.now()
            }]
        }
        
        # Save to Firestore
        inquiry_ref = db.collection("inquiries").add(inquiry_data)
        inquiry_id = inquiry_ref[1].id
        
        return {
            "id": inquiry_id,
            "message": "Inquiry created successfully"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create inquiry: {str(e)}"
        )

@app.get("/api/inquiries/farmer", tags=["Inquiries"])
async def get_farmer_inquiries(current_user: dict = Depends(get_current_user)):
    """Get all inquiries for a farmer"""
    try:
        inquiries_ref = db.collection("inquiries").where("farmerId", "==", current_user["uid"])
        inquiries = inquiries_ref.stream()
        
        inquiry_list = []
        for inquiry in inquiries:
            inquiry_data = inquiry.to_dict()
            inquiry_data["id"] = inquiry.id
            inquiry_list.append(inquiry_data)
        
        return inquiry_list
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch inquiries: {str(e)}"
        )

@app.get("/api/inquiries/consumer", tags=["Inquiries"])
async def get_consumer_messages(current_user: dict = Depends(get_current_user)):
    """Get all messages sent by a consumer"""
    try:
        inquiries_ref = db.collection("inquiries").where("consumerId", "==", current_user["uid"])
        inquiries = inquiries_ref.stream()
        
        inquiry_list = []
        for inquiry in inquiries:
            inquiry_data = inquiry.to_dict()
            inquiry_data["id"] = inquiry.id
            inquiry_list.append(inquiry_data)
        
        return inquiry_list
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch messages: {str(e)}"
        )

@app.get("/api/inquiries/{inquiry_id}", tags=["Inquiries"])
async def get_inquiry_details(inquiry_id: str, current_user: dict = Depends(get_current_user)):
    """Get specific inquiry details"""
    try:
        inquiry_ref = db.collection("inquiries").document(inquiry_id)
        inquiry_doc = inquiry_ref.get()
        
        if not inquiry_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Inquiry not found"
            )
        
        inquiry_data = inquiry_doc.to_dict()
        
        # Check if user has access to this inquiry
        if (inquiry_data["consumerId"] != current_user["uid"] and 
            inquiry_data["farmerId"] != current_user["uid"]):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied"
            )
        
        inquiry_data["id"] = inquiry_id
        return inquiry_data
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch inquiry: {str(e)}"
        )

@app.post("/api/inquiries/{inquiry_id}/messages", tags=["Inquiries"])
async def send_inquiry_message(inquiry_id: str, message_data: dict, current_user: dict = Depends(get_current_user)):
    """Send a message in an inquiry"""
    try:
        message = message_data.get("message")
        
        if not message:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Message is required"
            )
        
        inquiry_ref = db.collection("inquiries").document(inquiry_id)
        inquiry_doc = inquiry_ref.get()
        
        if not inquiry_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Inquiry not found"
            )
        
        inquiry_data = inquiry_doc.to_dict()
        
        # Check if user has access to this inquiry
        if (inquiry_data["consumerId"] != current_user["uid"] and 
            inquiry_data["farmerId"] != current_user["uid"]):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied"
            )
        
        # Add new message with unique ID
        import uuid
        message_id = str(uuid.uuid4())
        new_message = {
            "messageId": message_id,
            "senderId": current_user["uid"],
            "message": message,
            "timestamp": datetime.now()
        }
        
        # Update inquiry with new message
        inquiry_ref.update({
            "messages": firestore.ArrayUnion([new_message]),
            "updatedAt": datetime.now()
        })
        
        return {
            "message": "Message sent successfully"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to send message: {str(e)}"
        )

@app.put("/api/inquiries/{inquiry_id}/status", tags=["Inquiries"])
async def update_inquiry_status(inquiry_id: str, status_data: dict, current_user: dict = Depends(get_current_user)):
    """Update inquiry status (farmer only)"""
    try:
        new_status = status_data.get("status")
        
        if not new_status:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Status is required"
            )
        
        inquiry_ref = db.collection("inquiries").document(inquiry_id)
        inquiry_doc = inquiry_ref.get()
        
        if not inquiry_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Inquiry not found"
            )
        
        inquiry_data = inquiry_doc.to_dict()
        
        # Check if user is the farmer
        if inquiry_data["farmerId"] != current_user["uid"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the farmer can update inquiry status"
            )
        
        # Update status
        inquiry_ref.update({
            "status": new_status,
            "updatedAt": datetime.now()
        })
        
        return {
            "message": "Inquiry status updated successfully"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update inquiry status: {str(e)}"
        )

@app.put("/api/inquiries/{inquiry_id}/hide", tags=["Inquiries"])
async def hide_inquiry(inquiry_id: str, hide_data: dict, current_user: dict = Depends(get_current_user)):
    """Hide/unhide an inquiry"""
    try:
        hidden = hide_data.get("hidden", True)
        
        inquiry_ref = db.collection("inquiries").document(inquiry_id)
        inquiry_doc = inquiry_ref.get()
        
        if not inquiry_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Inquiry not found"
            )
        
        inquiry_data = inquiry_doc.to_dict()
        
        # Check if user has access to this inquiry
        if (inquiry_data["consumerId"] != current_user["uid"] and 
            inquiry_data["farmerId"] != current_user["uid"]):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied"
            )
        
        # Update hidden status
        inquiry_ref.update({
            "hidden": hidden,
            "hiddenBy": current_user["uid"] if hidden else None,
            "hiddenAt": datetime.now() if hidden else None,
            "updatedAt": datetime.now()
        })
        
        action = "hidden" if hidden else "unhidden"
        return {
            "message": f"Inquiry {action} successfully"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to hide inquiry: {str(e)}"
        )

@app.get("/api/inquiries/hidden", tags=["Inquiries"])
async def get_hidden_inquiries(current_user: dict = Depends(get_current_user)):
    """Get hidden inquiries for current user"""
    try:
        inquiries_ref = db.collection("inquiries").where("hidden", "==", True).where("hiddenBy", "==", current_user["uid"])
        inquiries = inquiries_ref.stream()
        
        inquiry_list = []
        for inquiry in inquiries:
            inquiry_data = inquiry.to_dict()
            inquiry_data["id"] = inquiry.id
            inquiry_list.append(inquiry_data)
        
        return inquiry_list
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch hidden inquiries: {str(e)}"
        )

@app.delete("/api/inquiries/{inquiry_id}/messages/{message_id}", tags=["Inquiries"])
async def delete_message(inquiry_id: str, message_id: str, current_user: dict = Depends(get_current_user)):
    """Delete a specific message (only own messages)"""
    try:
        inquiry_ref = db.collection("inquiries").document(inquiry_id)
        inquiry_doc = inquiry_ref.get()
        
        if not inquiry_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Inquiry not found"
            )
        
        inquiry_data = inquiry_doc.to_dict()
        
        # Check if user has access to this inquiry
        if (inquiry_data["consumerId"] != current_user["uid"] and 
            inquiry_data["farmerId"] != current_user["uid"]):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied"
            )
        
        # Find and remove the message
        messages = inquiry_data.get("messages", [])
        message_found = False
        
        for i, message in enumerate(messages):
            # Check if this is the message to delete and if it belongs to current user
            if (message.get("senderId") == current_user["uid"] and 
                message.get("messageId") == message_id):
                messages.pop(i)
                message_found = True
                break
        
        if not message_found:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Message not found or you don't have permission to delete it"
            )
        
        # Update the inquiry with modified messages
        inquiry_ref.update({
            "messages": messages,
            "updatedAt": datetime.now()
        })
        
        return {
            "message": "Message deleted successfully"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete message: {str(e)}"
        )

@app.delete("/api/inquiries/{inquiry_id}", tags=["Inquiries"])
async def delete_inquiry(inquiry_id: str, current_user: dict = Depends(get_current_user)):
    """Delete an entire inquiry/conversation (only by consumer)"""
    try:
        inquiry_ref = db.collection("inquiries").document(inquiry_id)
        inquiry_doc = inquiry_ref.get()
        
        if not inquiry_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Inquiry not found"
            )
        
        inquiry_data = inquiry_doc.to_dict()
        
        # Check if user is the consumer (only consumers can delete entire conversations)
        if inquiry_data["consumerId"] != current_user["uid"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the consumer can delete this conversation"
            )
        
        # Delete the entire inquiry document
        inquiry_ref.delete()
        
        return {
            "message": "Inquiry deleted successfully"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete inquiry: {str(e)}"
        )

if __name__ == "__main__":
    uvicorn.run(
        "main_firebase:app",
        host="0.0.0.0",
        port=8001,
        reload=True
    )
