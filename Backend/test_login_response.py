#!/usr/bin/env python3
"""
Test script to check the actual login response structure
"""

import requests
import json

# Backend URL
BASE_URL = "http://192.168.1.157:8001"

def test_login_response():
    """Test login response structure"""
    
    print("🔵 Testing consumer login response structure...")
    login_data = {
        "email": "consumer@test.com",
        "password": "password123"
    }
    
    response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
    print(f"Login response status: {response.status_code}")
    
    if response.status_code == 200:
        login_result = response.json()
        user_data = login_result.get("user", {})
        
        print(f"✅ Login successful!")
        print(f"Full response structure:")
        print(json.dumps(login_result, indent=2))
        
        print(f"\n🔍 User data analysis:")
        print(f"User type: {user_data.get('userType')}")
        print(f"Display name: {user_data.get('displayName')}")
        print(f"Phone: {user_data.get('phone')}")
        print(f"Location: {user_data.get('location')}")
        print(f"Bio: {user_data.get('bio')}")
        print(f"Consumer profile exists: {'consumerProfile' in user_data}")
        if 'consumerProfile' in user_data:
            print(f"Consumer profile: {user_data['consumerProfile']}")
        
    else:
        print(f"❌ Consumer login failed: {response.text}")

if __name__ == "__main__":
    print("🧪 Testing Login Response Structure")
    print("=" * 50)
    
    try:
        test_login_response()
        print("\n✅ Test completed!")
    except Exception as e:
        print(f"❌ Test failed with error: {e}")
