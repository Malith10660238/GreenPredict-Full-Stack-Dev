#!/usr/bin/env python3
"""
Simple test for inquiry system
"""

import requests
import json

BASE_URL = "http://10.224.79.220:8001"

def test_simple_inquiry():
    print("🧪 Simple Inquiry Test")
    print("=" * 30)
    
    # Login as consumer
    print("1. Logging in as consumer...")
    login_data = {"email": "consumer@test.com", "password": "password123"}
    response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
    
    if response.status_code != 200:
        print(f"❌ Login failed: {response.status_code}")
        return False
    
    consumer_data = response.json()
    consumer_token = consumer_data.get("access_token")
    print("✅ Consumer logged in")
    
    # Test creating inquiry with test endpoint
    print("\n2. Testing inquiry creation...")
    inquiry_data = {
        "farmerId": "2qBsMZEOQ0MY1EFfxTz4dgl3s9i1",  # Known farmer ID
        "productId": "test-product-123",
        "message": "Test inquiry message"
    }
    
    headers = {"Authorization": f"Bearer {consumer_token}"}
    response = requests.post(f"{BASE_URL}/test-create-inquiry", json=inquiry_data, headers=headers)
    
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
    
    if response.status_code == 200:
        print("✅ Test inquiry created successfully!")
        return True
    else:
        print("❌ Test inquiry failed")
        return False

if __name__ == "__main__":
    test_simple_inquiry()
