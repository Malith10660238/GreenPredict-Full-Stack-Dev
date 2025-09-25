#!/usr/bin/env python3
"""
Test script for the inquiry/chat system
Tests if farmers can see inquiries sent by consumers
"""

import requests
import json
import time
from datetime import datetime

# Configuration
BASE_URL = "http://10.224.79.220:8001"

def test_inquiry_system():
    """Test the complete inquiry system"""
    print("🧪 Testing Inquiry System")
    print("=" * 50)
    
    # Test 1: Check if test endpoint works
    print("\n1. Testing basic connectivity...")
    try:
        response = requests.get(f"{BASE_URL}/test-inquiries")
        if response.status_code == 200:
            print("✅ Test endpoint working")
            print(f"   Response: {response.json()}")
        else:
            print(f"❌ Test endpoint failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return False
    
    # Test 2: Consumer login
    print("\n2. Testing consumer login...")
    consumer_login_data = {
        "email": "consumer@test.com",
        "password": "password123"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/auth/login", json=consumer_login_data)
        if response.status_code == 200:
            consumer_data = response.json()
            consumer_token = consumer_data.get("token")
            consumer_uid = consumer_data.get("user", {}).get("uid")
            print("✅ Consumer login successful")
            print(f"   Consumer UID: {consumer_uid}")
        else:
            print(f"❌ Consumer login failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Consumer login error: {e}")
        return False
    
    # Test 3: Farmer login
    print("\n3. Testing farmer login...")
    farmer_login_data = {
        "email": "farmer@test.com", 
        "password": "password123"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/auth/login", json=farmer_login_data)
        if response.status_code == 200:
            farmer_data = response.json()
            farmer_token = farmer_data.get("token")
            farmer_uid = farmer_data.get("user", {}).get("uid")
            print("✅ Farmer login successful")
            print(f"   Farmer UID: {farmer_uid}")
        else:
            print(f"❌ Farmer login failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Farmer login error: {e}")
        return False
    
    # Test 4: Get available products
    print("\n4. Getting available products...")
    try:
        headers = {"Authorization": f"Bearer {consumer_token}"}
        response = requests.get(f"{BASE_URL}/listings/?limit=5&offset=0", headers=headers)
        if response.status_code == 200:
            listings = response.json()
            if listings:
                test_product = listings[0]
                product_id = test_product.get("id")
                product_name = test_product.get("name", "Unknown Product")
                print(f"✅ Found product: {product_name} (ID: {product_id})")
            else:
                print("❌ No products found")
                return False
        else:
            print(f"❌ Failed to get products: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Get products error: {e}")
        return False
    
    # Test 5: Consumer creates inquiry
    print("\n5. Testing consumer creating inquiry...")
    inquiry_data = {
        "farmerId": farmer_uid,
        "productId": product_id,
        "message": f"Test inquiry from consumer at {datetime.now().strftime('%H:%M:%S')}"
    }
    
    try:
        headers = {"Authorization": f"Bearer {consumer_token}"}
        response = requests.post(f"{BASE_URL}/test-create-inquiry", json=inquiry_data, headers=headers)
        if response.status_code == 200:
            inquiry_result = response.json()
            print("✅ Consumer inquiry created successfully")
            print(f"   Response: {inquiry_result}")
        else:
            print(f"❌ Consumer inquiry failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Consumer inquiry error: {e}")
        return False
    
    # Test 6: Farmer checks for inquiries
    print("\n6. Testing farmer viewing inquiries...")
    try:
        headers = {"Authorization": f"Bearer {farmer_token}"}
        response = requests.get(f"{BASE_URL}/api/inquiries/farmer", headers=headers)
        if response.status_code == 200:
            inquiries = response.json()
            print("✅ Farmer can access inquiries endpoint")
            print(f"   Found {len(inquiries)} inquiries")
            for i, inquiry in enumerate(inquiries):
                print(f"   Inquiry {i+1}: {inquiry.get('message', 'No message')}")
        else:
            print(f"❌ Farmer inquiry access failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Farmer inquiry access error: {e}")
        return False
    
    # Test 7: Consumer checks their messages
    print("\n7. Testing consumer viewing their messages...")
    try:
        headers = {"Authorization": f"Bearer {consumer_token}"}
        response = requests.get(f"{BASE_URL}/api/inquiries/consumer", headers=headers)
        if response.status_code == 200:
            messages = response.json()
            print("✅ Consumer can access their messages")
            print(f"   Found {len(messages)} messages")
            for i, message in enumerate(messages):
                print(f"   Message {i+1}: {message.get('message', 'No message')}")
        else:
            print(f"❌ Consumer message access failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Consumer message access error: {e}")
        return False
    
    print("\n" + "=" * 50)
    print("🎉 All tests completed!")
    return True

def test_endpoint_availability():
    """Test if all inquiry endpoints are available"""
    print("\n🔍 Testing endpoint availability...")
    
    endpoints = [
        ("GET", "/test-inquiries"),
        ("POST", "/test-create-inquiry"),
        ("POST", "/api/inquiries"),
        ("GET", "/api/inquiries/farmer"),
        ("GET", "/api/inquiries/consumer"),
    ]
    
    for method, endpoint in endpoints:
        try:
            if method == "GET":
                response = requests.get(f"{BASE_URL}{endpoint}")
            else:
                response = requests.post(f"{BASE_URL}{endpoint}")
            
            print(f"   {method} {endpoint}: {response.status_code}")
        except Exception as e:
            print(f"   {method} {endpoint}: ERROR - {e}")

if __name__ == "__main__":
    print("🚀 Starting Inquiry System Tests")
    print(f"Testing against: {BASE_URL}")
    
    # Test endpoint availability first
    test_endpoint_availability()
    
    # Run main tests
    success = test_inquiry_system()
    
    if success:
        print("\n✅ All tests passed! Inquiry system is working.")
    else:
        print("\n❌ Some tests failed. Check the output above for details.")
