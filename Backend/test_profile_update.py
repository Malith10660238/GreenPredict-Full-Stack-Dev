#!/usr/bin/env python3
"""
Test script to verify profile update functionality
"""

import requests
import json

# Backend URL
BASE_URL = "http://192.168.1.157:8001"

def test_profile_update():
    """Test profile update functionality"""
    
    # Test farmer login
    print("🔵 Testing farmer login...")
    login_data = {
        "email": "farmer@test.com",
        "password": "password123"
    }
    
    response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
    print(f"Login response status: {response.status_code}")
    
    if response.status_code == 200:
        login_result = response.json()
        token = login_result.get("access_token")
        user_data = login_result.get("user", {})
        
        print(f"✅ Login successful!")
        print(f"User: {user_data.get('displayName')} ({user_data.get('userType')})")
        print(f"Token: {token[:20]}...")
        
        # Test profile update
        print("\n🔵 Testing profile update...")
        profile_update_data = {
            "firstName": "John",
            "lastName": "Farmer",
            "displayName": "John Farmer",
            "phone": "+94771234567",
            "location": "Colombo, Sri Lanka",
            "bio": "Experienced organic farmer with 10+ years of experience",
            "farmName": "Green Valley Farm",
            "farmSize": "15 acres",
            "farmingExperience": "15 years",
            "certification": "Organic Certified"
        }
        
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        update_response = requests.put(f"{BASE_URL}/profile/", json=profile_update_data, headers=headers)
        print(f"Profile update response status: {update_response.status_code}")
        
        if update_response.status_code == 200:
            update_result = update_response.json()
            print("✅ Profile update successful!")
            print(f"Response: {json.dumps(update_result, indent=2)}")
        else:
            print(f"❌ Profile update failed: {update_response.text}")
    
    else:
        print(f"❌ Login failed: {response.text}")

def test_consumer_profile_update():
    """Test consumer profile update"""
    
    print("\n🔵 Testing consumer login...")
    login_data = {
        "email": "consumer@test.com",
        "password": "password123"
    }
    
    response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
    print(f"Login response status: {response.status_code}")
    
    if response.status_code == 200:
        login_result = response.json()
        token = login_result.get("access_token")
        user_data = login_result.get("user", {})
        
        print(f"✅ Login successful!")
        print(f"User: {user_data.get('displayName')} ({user_data.get('userType')})")
        
        # Test consumer profile update
        print("\n🔵 Testing consumer profile update...")
        profile_update_data = {
            "firstName": "Jane",
            "lastName": "Consumer",
            "displayName": "Jane Consumer",
            "phone": "+94771234568",
            "location": "Kandy, Sri Lanka",
            "bio": "Health-conscious consumer who loves fresh organic produce",
            "preferences": ["organic", "local", "fresh"]
        }
        
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        update_response = requests.put(f"{BASE_URL}/profile/", json=profile_update_data, headers=headers)
        print(f"Profile update response status: {update_response.status_code}")
        
        if update_response.status_code == 200:
            update_result = update_response.json()
            print("✅ Consumer profile update successful!")
            print(f"Response: {json.dumps(update_result, indent=2)}")
        else:
            print(f"❌ Consumer profile update failed: {update_response.text}")
    
    else:
        print(f"❌ Consumer login failed: {response.text}")

if __name__ == "__main__":
    print("🧪 Testing Profile Update Functionality")
    print("=" * 50)
    
    try:
        test_profile_update()
        test_consumer_profile_update()
        print("\n✅ All tests completed!")
    except Exception as e:
        print(f"❌ Test failed with error: {e}")
