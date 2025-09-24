#!/usr/bin/env python3
"""
Test script to verify consumer profile display issue
"""

import requests
import json

# Backend URL
BASE_URL = "http://192.168.1.157:8001"

def test_consumer_profile_display():
    """Test consumer profile display"""
    
    print("🔵 Testing consumer login and profile data...")
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
        print(f"User: {user_data.get('displayName')} ({user_data.get('userType')})")
        print(f"Phone: {user_data.get('phone')}")
        print(f"Location: {user_data.get('location')}")
        print(f"Bio: {user_data.get('bio')}")
        print(f"Preferences: {user_data.get('consumerProfile', {}).get('preferences')}")
        
        # Test profile update with different data
        print("\n🔵 Testing consumer profile update with new data...")
        profile_update_data = {
            "firstName": "Updated",
            "lastName": "Consumer",
            "displayName": "Updated Consumer",
            "phone": "+94771234599",
            "location": "Galle, Sri Lanka",
            "bio": "Updated bio for testing display",
            "preferences": ["organic", "fresh", "local", "healthy"]
        }
        
        token = login_result.get("access_token")
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        update_response = requests.put(f"{BASE_URL}/profile/", json=profile_update_data, headers=headers)
        print(f"Profile update response status: {update_response.status_code}")
        
        if update_response.status_code == 200:
            update_result = update_response.json()
            updated_user = update_result.get("user", {})
            print("✅ Consumer profile update successful!")
            print(f"Updated Display Name: {updated_user.get('displayName')}")
            print(f"Updated Phone: {updated_user.get('phone')}")
            print(f"Updated Location: {updated_user.get('location')}")
            print(f"Updated Bio: {updated_user.get('bio')}")
            print(f"Updated Preferences: {updated_user.get('consumerProfile', {}).get('preferences')}")
            
            # Verify the data structure
            print("\n🔍 Data structure analysis:")
            print(f"Response has 'user' key: {'user' in update_result}")
            print(f"User has 'displayName': {'displayName' in updated_user}")
            print(f"User has 'phone': {'phone' in updated_user}")
            print(f"User has 'location': {'location' in updated_user}")
            print(f"User has 'bio': {'bio' in updated_user}")
            print(f"User has 'consumerProfile': {'consumerProfile' in updated_user}")
            
        else:
            print(f"❌ Consumer profile update failed: {update_response.text}")
    
    else:
        print(f"❌ Consumer login failed: {response.text}")

if __name__ == "__main__":
    print("🧪 Testing Consumer Profile Display Issue")
    print("=" * 50)
    
    try:
        test_consumer_profile_display()
        print("\n✅ Test completed!")
    except Exception as e:
        print(f"❌ Test failed with error: {e}")
