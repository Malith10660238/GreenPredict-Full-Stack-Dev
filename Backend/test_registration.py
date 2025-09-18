import requests
import json

def test_registration():
    url = "http://localhost:8001/auth/register"
    data = {
        "email": "test@example.com",
        "password": "password123",
        "first_name": "Test",
        "last_name": "User",
        "user_type": "farmer"
    }
    
    try:
        print("Testing registration endpoint...")
        response = requests.post(url, json=data)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            print("✅ Registration successful!")
        else:
            print("❌ Registration failed!")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_registration()
