#!/usr/bin/env python3
"""
Test password authentication
"""

import requests
import json

# Backend URL
BASE_URL = "http://192.168.1.157:8001"

def test_password_auth():
    """Test password authentication"""
    
    print("🧪 Testing Password Authentication")
    print("=" * 50)
    
    # Test 1: Correct farmer credentials
    print("\n🔵 Test 1: Correct farmer credentials")
    login_data = {
        "email": "farmer@test.com",
        "password": "password123"
    }
    
    response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        print("✅ Login successful with correct farmer credentials")
    else:
        print(f"❌ Login failed: {response.text}")
    
    # Test 2: Correct consumer credentials
    print("\n🔵 Test 2: Correct consumer credentials")
    login_data = {
        "email": "consumer@test.com",
        "password": "password123"
    }
    
    response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        print("✅ Login successful with correct consumer credentials")
    else:
        print(f"❌ Login failed: {response.text}")
    
    # Test 3: Wrong password for farmer
    print("\n🔵 Test 3: Wrong password for farmer")
    login_data = {
        "email": "farmer@test.com",
        "password": "wrongpassword"
    }
    
    response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
    print(f"Status: {response.status_code}")
    if response.status_code == 401:
        print("✅ Login correctly rejected with wrong password")
    else:
        print(f"❌ Login should have failed: {response.text}")
    
    # Test 4: Wrong password for consumer
    print("\n🔵 Test 4: Wrong password for consumer")
    login_data = {
        "email": "consumer@test.com",
        "password": "wrongpassword"
    }
    
    response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
    print(f"Status: {response.status_code}")
    if response.status_code == 401:
        print("✅ Login correctly rejected with wrong password")
    else:
        print(f"❌ Login should have failed: {response.text}")
    
    # Test 5: Non-existent email
    print("\n🔵 Test 5: Non-existent email")
    login_data = {
        "email": "nonexistent@test.com",
        "password": "password123"
    }
    
    response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
    print(f"Status: {response.status_code}")
    if response.status_code == 401:
        print("✅ Login correctly rejected with non-existent email")
    else:
        print(f"❌ Login should have failed: {response.text}")
    
    # Test 6: Empty password
    print("\n🔵 Test 6: Empty password")
    login_data = {
        "email": "farmer@test.com",
        "password": ""
    }
    
    response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
    print(f"Status: {response.status_code}")
    if response.status_code == 400:
        print("✅ Login correctly rejected with empty password")
    else:
        print(f"❌ Login should have failed: {response.text}")

if __name__ == "__main__":
    try:
        test_password_auth()
        print("\n✅ All password authentication tests completed!")
    except Exception as e:
        print(f"❌ Test failed with error: {e}")
