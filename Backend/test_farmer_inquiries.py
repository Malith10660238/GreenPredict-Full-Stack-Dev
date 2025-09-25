#!/usr/bin/env python3
"""
Test if farmers can see inquiries sent by consumers
"""

import requests
import json
import time

BASE_URL = "http://10.224.79.220:8001"

def test_farmer_inquiries():
    print("🧪 Testing Farmer Inquiry Visibility")
    print("=" * 40)
    
    # Step 1: Consumer login and create inquiry
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
    
    # Step 2: Get a real product first
    print("\n2. Getting available products...")
    headers = {"Authorization": f"Bearer {consumer_token}"}
    response = requests.get(f"{BASE_URL}/listings/?limit=1&offset=0", headers=headers)
    
    if response.status_code != 200:
        print(f"❌ Failed to get products: {response.status_code}")
        return False
    
    products = response.json()
    if not products:
        print("❌ No products available")
        return False
    
    product = products[0]
    product_id = product.get("id")
    farmer_id = product.get("farmerId")
    print(f"✅ Using product: {product.get('name')} (ID: {product_id})")
    print(f"   Farmer ID: {farmer_id}")
    
    # Step 3: Create inquiry
    print("\n3. Creating inquiry...")
    inquiry_data = {
        "farmerId": farmer_id,
        "productId": product_id,
        "message": f"Test inquiry from consumer at {time.strftime('%H:%M:%S')}"
    }
    
    headers = {"Authorization": f"Bearer {consumer_token}"}
    response = requests.post(f"{BASE_URL}/api/inquiries", json=inquiry_data, headers=headers)
    
    print(f"   Status: {response.status_code}")
    print(f"   Response: {response.text}")
    
    if response.status_code != 200:
        print("❌ Inquiry creation failed")
        return False
    
    inquiry_result = response.json()
    inquiry_id = inquiry_result.get("id")
    print(f"✅ Inquiry created: {inquiry_id}")
    
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
    
    if response.status_code != 200:
        print("❌ Farmer inquiry access failed")
        return False
    
    inquiries = response.json()
    print(f"✅ Farmer found {len(inquiries)} inquiries")
    
    # Check if our inquiry is in the list
    found_inquiry = False
    for inquiry in inquiries:
        if inquiry.get("id") == inquiry_id:
            found_inquiry = True
            print(f"✅ Found our inquiry: {inquiry.get('message')}")
            break
    
    if not found_inquiry:
        print("❌ Our inquiry not found in farmer's list")
        return False
    
    # Step 6: Consumer checks their messages
    print("\n6. Consumer checking their messages...")
    headers = {"Authorization": f"Bearer {consumer_token}"}
    response = requests.get(f"{BASE_URL}/api/inquiries/consumer", headers=headers)
    
    print(f"   Status: {response.status_code}")
    print(f"   Response: {response.text}")
    
    if response.status_code != 200:
        print("❌ Consumer message access failed")
        return False
    
    messages = response.json()
    print(f"✅ Consumer found {len(messages)} messages")
    
    # Check if our message is in the list
    found_message = False
    for message in messages:
        if message.get("id") == inquiry_id:
            found_message = True
            print(f"✅ Found our message: {message.get('message')}")
            break
    
    if not found_message:
        print("❌ Our message not found in consumer's list")
        return False
    
    print("\n" + "=" * 40)
    print("🎉 All tests passed! Inquiry system is working correctly.")
    print("✅ Farmers can see inquiries sent by consumers")
    print("✅ Consumers can see their sent messages")
    return True

if __name__ == "__main__":
    test_farmer_inquiries()
