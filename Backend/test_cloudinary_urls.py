#!/usr/bin/env python3
"""
Test script to verify Cloudinary URLs are accessible
"""

import requests
import json

def test_cloudinary_urls():
    """Test if Cloudinary URLs are accessible"""
    print("Testing Cloudinary URLs accessibility...")
    print("=" * 50)
    
    # Sample Cloudinary URLs from your database
    test_urls = [
        "https://res.cloudinary.com/djvlvrsu3/image/upload/v1759301333/greenpredict/listing_images/listing_temp_1adfd712-477c-48f4-b2ef-a4b4f27464ac.jpg",
        "https://res.cloudinary.com/djvlvrsu3/image/upload/v1759301334/greenpredict/listing_images/listing_temp_eb3141e8-7004-42a2-ae35-1fac99f8adf6.jpg",
        "https://res.cloudinary.com/djvlvrsu3/image/upload/v1759301335/greenpredict/listing_images/listing_temp_05141551-242c-42b7-bde0-259b0eff3924.jpg",
        "https://res.cloudinary.com/djvlvrsu3/image/upload/v1759301336/greenpredict/listing_images/listing_temp_c71426bf-0770-4323-ad23-18a862a772ff.jpg"
    ]
    
    for i, url in enumerate(test_urls, 1):
        try:
            print(f"Testing URL {i}: {url}")
            response = requests.get(url, timeout=10)
            
            if response.status_code == 200:
                print(f"SUCCESS: Image {i} is accessible")
                print(f"   Content-Type: {response.headers.get('content-type', 'Unknown')}")
                print(f"   Content-Length: {len(response.content)} bytes")
            else:
                print(f"ERROR: Image {i} returned status {response.status_code}")
                
        except requests.exceptions.RequestException as e:
            print(f"ERROR: Image {i} failed to load: {e}")
        
        print()
    
    print("=" * 50)
    print("Cloudinary URL test completed!")

if __name__ == "__main__":
    test_cloudinary_urls()
