#!/usr/bin/env python3
"""
Comprehensive script to clean up ALL Firebase collections by removing non-Cloudinary image URLs.
This will ensure all images across the entire app are served from Cloudinary.
"""

import os
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore

load_dotenv()

def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    if not firebase_admin._apps:
        service_account_path = "serviceAccountKey.json"
        if os.path.exists(service_account_path):
            cred = credentials.Certificate(service_account_path)
            firebase_admin.initialize_app(cred)
            print("Firebase Admin SDK initialized successfully.")
        else:
            print("ERROR: serviceAccountKey.json not found. Please ensure it's in the Backend directory.")
            return None
    else:
        print("Firebase Admin SDK already initialized.")
    
    return firestore.client()

def is_cloudinary_url(url):
    """Check if a URL is a valid Cloudinary URL"""
    if not isinstance(url, str):
        return False
    return "https://res.cloudinary.com/djvlvrsu3/" in url

def clean_collection(db, collection_name, image_fields):
    """Clean a specific collection for non-Cloudinary image URLs"""
    print(f"\nCleaning {collection_name} collection...")
    print("-" * 40)
    
    collection_ref = db.collection(collection_name)
    docs = collection_ref.stream()
    
    cleaned_count = 0
    total_images_removed = 0
    
    for doc in docs:
        doc_data = doc.to_dict()
        doc_id = doc.id
        updated = False
        updates = {}
        
        for field in image_fields:
            if field in doc_data:
                value = doc_data[field]
                
                if isinstance(value, str):
                    # Single image URL
                    if not is_cloudinary_url(value):
                        print(f"  {collection_name} {doc_id}: Removing non-Cloudinary {field}: {value}")
                        updates[field] = ''
                        updated = True
                        total_images_removed += 1
                elif isinstance(value, list):
                    # List of image URLs
                    cloudinary_images = []
                    for img_url in value:
                        if is_cloudinary_url(img_url):
                            cloudinary_images.append(img_url)
                        else:
                            print(f"  {collection_name} {doc_id}: Removing non-Cloudinary {field}: {img_url}")
                            total_images_removed += 1
                    
                    if len(cloudinary_images) != len(value):
                        updates[field] = cloudinary_images
                        updated = True
        
        if updated:
            collection_ref.document(doc_id).update(updates)
            cleaned_count += 1
    
    print(f"  Cleaned {cleaned_count} documents in {collection_name}")
    print(f"  Removed {total_images_removed} non-Cloudinary images")
    return cleaned_count, total_images_removed

def clean_all_images():
    """
    Clean up ALL Firebase collections for non-Cloudinary image URLs.
    """
    db = initialize_firebase()
    if not db:
        return

    print("Starting comprehensive Firebase image cleanup...")
    print("=" * 60)

    total_cleaned = 0
    total_images_removed = 0

    # Define collections and their image fields
    collections_to_clean = [
        {
            'name': 'users',
            'image_fields': ['profileImageUrl', 'profile_image_url']
        },
        {
            'name': 'listings',
            'image_fields': ['images', 'image_urls']
        },
        {
            'name': 'inquiries',
            'image_fields': ['images', 'image_urls']
        },
        {
            'name': 'messages',
            'image_fields': ['imageUrl', 'image_url']
        }
    ]

    for collection_info in collections_to_clean:
        try:
            cleaned, removed = clean_collection(db, collection_info['name'], collection_info['image_fields'])
            total_cleaned += cleaned
            total_images_removed += removed
        except Exception as e:
            print(f"  Error cleaning {collection_info['name']}: {e}")

    print("\n" + "=" * 60)
    print("Comprehensive Firebase image cleanup completed!")
    print(f"Total documents cleaned: {total_cleaned}")
    print(f"Total non-Cloudinary images removed: {total_images_removed}")
    print("Please restart your Flutter app to see the changes reflected.")

if __name__ == "__main__":
    clean_all_images()
