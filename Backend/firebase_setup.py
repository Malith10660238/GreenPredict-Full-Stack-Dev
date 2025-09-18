"""
Firebase setup script for GreenPredict Backend
This script helps initialize Firebase collections and indexes
"""

import firebase_admin
from firebase_admin import credentials, firestore
import os
import json

def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    if not firebase_admin._apps:
        # Check if service account key file exists
        service_account_path = "serviceAccountKey.json"
        if os.path.exists(service_account_path):
            cred = credentials.Certificate(service_account_path)
            firebase_admin.initialize_app(cred)
        else:
            print("Warning: serviceAccountKey.json not found. Make sure to place your Firebase service account key in the Backend directory.")
            return None
    
    return firestore.client()

def create_firestore_indexes():
    """Create Firestore indexes for better query performance"""
    print("Creating Firestore indexes...")
    
    # Note: Firestore indexes are typically created through the Firebase Console
    # or using the Firebase CLI. This is just a reference of what indexes you might need.
    
    indexes = [
        {
            "collection": "listings",
            "fields": [
                {"field": "status", "order": "ASCENDING"},
                {"field": "created_at", "order": "DESCENDING"}
            ]
        },
        {
            "collection": "listings",
            "fields": [
                {"field": "farmer_id", "order": "ASCENDING"},
                {"field": "created_at", "order": "DESCENDING"}
            ]
        },
        {
            "collection": "listings",
            "fields": [
                {"field": "location", "order": "ASCENDING"},
                {"field": "status", "order": "ASCENDING"},
                {"field": "created_at", "order": "DESCENDING"}
            ]
        },
        {
            "collection": "predictions",
            "fields": [
                {"field": "user_id", "order": "ASCENDING"},
                {"field": "created_at", "order": "DESCENDING"}
            ]
        }
    ]
    
    print("Required Firestore indexes:")
    for index in indexes:
        print(f"- Collection: {index['collection']}")
        print(f"  Fields: {[f['field'] for f in index['fields']]}")
    
    print("\nTo create these indexes:")
    print("1. Go to Firebase Console > Firestore > Indexes")
    print("2. Click 'Create Index' and add the above indexes")
    print("3. Or use Firebase CLI: firebase firestore:indexes")

def create_sample_data():
    """Create sample data for testing"""
    db = initialize_firebase()
    if not db:
        return
    
    print("Creating sample data...")
    
    # Sample user data
    sample_users = [
        {
            "uid": "sample_farmer_1",
            "email": "farmer1@example.com",
            "first_name": "Sunil",
            "last_name": "Perera",
            "display_name": "Sunil Perera",
            "user_type": "farmer",
            "phone": "+94 77 123 4567",
            "location": "Nuwara Eliya",
            "bio": "Passionate organic farmer with 15+ years of experience",
            "join_date": "2024-01-01T00:00:00Z",
            "rating": 4.8,
            "total_reviews": 127,
            "farmer_profile": {
                "farm_name": "Green Valley Organic Farm",
                "farm_size": "5 acres",
                "crops": ["Rice", "Vegetables", "Fruits", "Herbs"],
                "farming_experience": "15 years",
                "total_listings": 12,
                "total_sales": 45,
                "certification": "Organic Certified"
            },
            "created_at": "2024-01-01T00:00:00Z",
            "updated_at": "2024-01-01T00:00:00Z"
        },
        {
            "uid": "sample_consumer_1",
            "email": "consumer1@example.com",
            "first_name": "Nimali",
            "last_name": "Silva",
            "display_name": "Nimali Silva",
            "user_type": "consumer",
            "phone": "+94 77 987 6543",
            "location": "Colombo",
            "bio": "Health-conscious consumer who loves fresh, organic produce",
            "join_date": "2024-01-15T00:00:00Z",
            "rating": 4.9,
            "total_reviews": 45,
            "consumer_profile": {
                "preferences": ["Organic", "Local", "Fresh"],
                "total_orders": 23,
                "total_spent": 1250.50,
                "favorite_crops": ["Tomatoes", "Lettuce", "Carrots"]
            },
            "created_at": "2024-01-15T00:00:00Z",
            "updated_at": "2024-01-15T00:00:00Z"
        }
    ]
    
    # Add sample users
    for user in sample_users:
        db.collection('users').document(user['uid']).set(user)
        print(f"Created sample user: {user['display_name']}")
    
    # Sample listing data
    sample_listings = [
        {
            "crop_name": "Fresh Tomatoes",
            "farmer_id": "sample_farmer_1",
            "farmer_name": "Sunil Perera",
            "price": 180.0,
            "quantity": 50,
            "location": "Nuwara Eliya",
            "description": "Fresh organic tomatoes grown in highland climate",
            "contact": "+94 77 123 4567",
            "is_organic": True,
            "rating": 4.8,
            "images": ["https://picsum.photos/400/300?random=1"],
            "status": "active",
            "manufactured_date": "2024-01-20T00:00:00Z",
            "created_at": "2024-01-20T00:00:00Z",
            "updated_at": "2024-01-20T00:00:00Z"
        },
        {
            "crop_name": "Keeri Samba Rice",
            "farmer_id": "sample_farmer_1",
            "farmer_name": "Sunil Perera",
            "price": 280.0,
            "quantity": 150,
            "location": "Anuradhapura",
            "description": "High-quality Keeri Samba rice, directly from the paddy fields",
            "contact": "+94 77 123 4567",
            "is_organic": False,
            "rating": 4.5,
            "images": ["https://picsum.photos/400/300?random=2"],
            "status": "active",
            "manufactured_date": "2024-01-18T00:00:00Z",
            "created_at": "2024-01-18T00:00:00Z",
            "updated_at": "2024-01-18T00:00:00Z"
        }
    ]
    
    # Add sample listings
    for listing in sample_listings:
        doc_ref = db.collection('listings').add(listing)
        print(f"Created sample listing: {listing['crop_name']}")
    
    print("Sample data created successfully!")

def main():
    """Main setup function"""
    print("GreenPredict Firebase Setup")
    print("=" * 30)
    
    # Initialize Firebase
    db = initialize_firebase()
    if not db:
        print("Firebase initialization failed. Please check your service account key.")
        return
    
    print("Firebase initialized successfully!")
    
    # Create indexes info
    create_firestore_indexes()
    
    # Ask if user wants to create sample data
    create_sample = input("\nDo you want to create sample data? (y/n): ").lower().strip()
    if create_sample == 'y':
        create_sample_data()
    
    print("\nSetup completed!")
    print("You can now run the FastAPI server with: python main.py")

if __name__ == "__main__":
    main()
