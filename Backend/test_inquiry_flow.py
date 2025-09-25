#!/usr/bin/env python3
"""
Test the complete inquiry flow without requiring real products
"""

import requests
import json
import time

BASE_URL = "http://10.224.79.220:8001"

def test_inquiry_flow():
    print("🧪 Testing Complete Inquiry Flow")
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
    consumer_uid = consumer_data.get("user", {}).get("uid")
    print(f"✅ Consumer logged in: {consumer_uid}")
    
    # Step 2: Create inquiry using test endpoint
    print("\n2. Creating inquiry (test endpoint)...")
    inquiry_data = {
        "farmerId": "2qBsMZEOQ0MY1EFfxTz4dgl3s9i1",  # Known farmer ID
        "productId": "test-product-789",
        "message": f"Test inquiry from consumer at {time.strftime('%H:%M:%S')}"
    }
    
    headers = {"Authorization": f"Bearer {consumer_token}"}
    response = requests.post(f"{BASE_URL}/test-create-inquiry", json=inquiry_data, headers=headers)
    
    print(f"   Status: {response.status_code}")
    print(f"   Response: {response.text}")
    
    if response.status_code != 200:
        print("❌ Test inquiry creation failed")
        return False
    
    print("✅ Test inquiry created successfully")
    
    # Step 3: Test real inquiry endpoint
    print("\n3. Testing real inquiry endpoint...")
    response = requests.post(f"{BASE_URL}/api/inquiries", json=inquiry_data, headers=headers)
    
    print(f"   Status: {response.status_code}")
    print(f"   Response: {response.text}")
    
    if response.status_code == 200:
        inquiry_result = response.json()
        inquiry_id = inquiry_result.get("id")
        print(f"✅ Real inquiry created: {inquiry_id}")
        
        # Step 4: Farmer login
        print("\n4. Farmer login...")
        farmer_login = {"email": "farmer@test.com", "password": "password123"}
        response = requests.post(f"{BASE_URL}/auth/login", json=farmer_login)
        
        if response.status_code != 200:
            print(f"❌ Farmer login failed: {response.status_code}")
            return False
        
        farmer_data = response.json()
        farmer_token = farmer_data.get("access_token")
        farmer_uid = farmer_data.get("user", {}).get("uid")
        print(f"✅ Farmer logged in: {farmer_uid}")
        
        # Step 5: Farmer checks for inquiries
        print("\n5. Farmer checking for inquiries...")
        headers = {"Authorization": f"Bearer {farmer_token}"}
        response = requests.get(f"{BASE_URL}/api/inquiries/farmer", headers=headers)
        
        print(f"   Status: {response.status_code}")
        print(f"   Response: {response.text}")
        
        if response.status_code == 200:
            inquiries = response.json()
            print(f"✅ Farmer found {len(inquiries)} inquiries")
            
            # Check if our inquiry is in the list
            found_inquiry = False
            for inquiry in inquiries:
                if inquiry.get("id") == inquiry_id:
                    found_inquiry = True
                    print(f"✅ Found our inquiry: {inquiry.get('message')}")
                    break
            
            if found_inquiry:
                print("\n" + "=" * 35)
                print("🎉 SUCCESS! Inquiry system is working!")
                print("✅ Consumer can create inquiries")
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
        print("❌ Real inquiry creation failed")
        return False

if __name__ == "__main__":
    test_inquiry_flow()
