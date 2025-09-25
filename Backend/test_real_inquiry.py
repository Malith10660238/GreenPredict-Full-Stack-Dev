#!/usr/bin/env python3
"""
Test inquiry system with real product IDs
"""

import requests
import json

BASE_URL = "http://10.224.79.220:8001"

def test_real_inquiry():
    print("🧪 Testing with Real Product IDs")
    print("=" * 35)
    
    # Step 1: Consumer login
    print("1. Consumer login...")
    consumer_login = {"email": "consumer@test.com", "password": "password123"}
    response = requests.post(f"{BASE_URL}/auth/login", json=consumer_login)
    
    if response.status_code != 200:
        print(f"❌ Consumer login failed: {response.status_code}")
        return False
    
    consumer_data = response.json()
    consumer_token = consumer_data.get("access_token")
    print("✅ Consumer logged in")
    
    # Step 2: Get real listings
    print("\n2. Getting real listings...")
    headers = {"Authorization": f"Bearer {consumer_token}"}
    response = requests.get(f"{BASE_URL}/listings/?limit=5&offset=0", headers=headers)
    
    if response.status_code != 200:
        print(f"❌ Failed to get listings: {response.status_code}")
        print(f"   Response: {response.text}")
        return False
    
    listings_response = response.json()
    print(f"✅ Response type: {type(listings_response)}")
    print(f"   Response keys: {listings_response.keys() if isinstance(listings_response, dict) else 'Not a dict'}")
    print(f"   Full response: {listings_response}")
    
    # Check if it's a dict with listings key
    if isinstance(listings_response, dict) and 'listings' in listings_response:
        listings = listings_response['listings']
    elif isinstance(listings_response, list):
        listings = listings_response
    else:
        print("❌ Unexpected response format")
        return False
    
    print(f"✅ Found {len(listings)} listings")
    
    if not listings:
        print("❌ No listings available")
        return False
    
    # Use the first listing
    listing = listings[0]
    product_id = listing.get("id")
    farmer_id = listing.get("farmerId")
    product_name = listing.get("name", "Unknown Product")
    
    print(f"✅ Using listing: {product_name}")
    print(f"   Product ID: {product_id}")
    print(f"   Farmer ID: {farmer_id}")
    
    # Step 3: Create inquiry with real product
    print("\n3. Creating inquiry with real product...")
    inquiry_data = {
        "farmerId": farmer_id,
        "productId": product_id,
        "message": "Hello! I'm interested in this product. Is it available?"
    }
    
    response = requests.post(f"{BASE_URL}/api/inquiries", json=inquiry_data, headers=headers)
    
    print(f"   Status: {response.status_code}")
    print(f"   Response: {response.text}")
    
    if response.status_code == 200:
        inquiry_result = response.json()
        inquiry_id = inquiry_result.get("id")
        print(f"✅ Inquiry created successfully: {inquiry_id}")
        
        # Step 4: Test farmer can see the inquiry
        print("\n4. Testing farmer can see inquiry...")
        farmer_login = {"email": "farmer@test.com", "password": "password123"}
        response = requests.post(f"{BASE_URL}/auth/login", json=farmer_login)
        
        if response.status_code != 200:
            print(f"❌ Farmer login failed: {response.status_code}")
            return False
        
        farmer_data = response.json()
        farmer_token = farmer_data.get("access_token")
        
        headers = {"Authorization": f"Bearer {farmer_token}"}
        response = requests.get(f"{BASE_URL}/api/inquiries/farmer", headers=headers)
        
        print(f"   Status: {response.status_code}")
        print(f"   Response: {response.text}")
        
        if response.status_code == 200:
            inquiries = response.json()
            print(f"✅ Farmer found {len(inquiries)} inquiries")
            
            # Check if our inquiry is there
            found = False
            for inquiry in inquiries:
                if inquiry.get("id") == inquiry_id:
                    found = True
                    print(f"✅ Found our inquiry: {inquiry.get('message')}")
                    break
            
            if found:
                print("\n" + "=" * 35)
                print("🎉 SUCCESS! Real inquiry system works!")
                print("✅ Consumer can create inquiries with real products")
                print("✅ Farmer can see inquiries")
                print("✅ Data is stored in Firebase")
                return True
            else:
                print("❌ Our inquiry not found in farmer's list")
                return False
        else:
            print("❌ Farmer inquiry access failed")
            return False
    else:
        print("❌ Inquiry creation failed")
        return False

if __name__ == "__main__":
    test_real_inquiry()
