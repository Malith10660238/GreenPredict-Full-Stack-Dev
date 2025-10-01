#!/usr/bin/env python3
"""
Script to clean up Firebase listings by removing non-Cloudinary image URLs.
This will help ensure all marketplace images are served from Cloudinary.
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

def clean_listings_images():
    """
    Iterate through all listings in Firebase and remove non-Cloudinary image URLs.
    """
    db = initialize_firebase()
    if not db:
        return

    print("Starting Firebase listings cleanup...")
    print("=" * 50)

    listings_ref = db.collection('listings')
    listings = listings_ref.stream()

    cleaned_listings_count = 0
    total_images_removed = 0

    for listing in listings:
        listing_data = listing.to_dict()
        listing_id = listing.id
        current_images = listing_data.get('images', [])
        
        if not current_images:
            print(f"Listing {listing_id}: No images found.")
            continue

        cloudinary_images = []
        removed_from_this_listing = 0

        for image_url in current_images:
            # Cloudinary URLs typically start with 'https://res.cloudinary.com/'
            # We'll also check for your specific cloud name 'djvlvrsu3'
            if isinstance(image_url, str) and "https://res.cloudinary.com/djvlvrsu3/" in image_url:
                cloudinary_images.append(image_url)
                print(f"  Listing {listing_id}: Keeping Cloudinary image: {image_url}")
            else:
                print(f"  Listing {listing_id}: Removing non-Cloudinary image: {image_url}")
                removed_from_this_listing += 1
        
        if removed_from_this_listing > 0:
            print(f"  Listing {listing_id}: Updating images. Removed {removed_from_this_listing} non-Cloudinary images.")
            listings_ref.document(listing_id).update({'images': cloudinary_images})
            cleaned_listings_count += 1
            total_images_removed += removed_from_this_listing
        else:
            print(f"Listing {listing_id}: All images are Cloudinary or no changes needed.")

    print("=" * 50)
    print("Firebase listings cleanup completed!")
    print(f"Cleaned {cleaned_listings_count} listings.")
    print(f"Total non-Cloudinary images removed: {total_images_removed}")
    print("Please restart your Flutter app to see the changes reflected.")

if __name__ == "__main__":
    clean_listings_images()
