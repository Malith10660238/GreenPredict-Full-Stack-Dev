import requests
import json

def test_complete_auth_flow():
    """Test the complete authentication and image upload flow"""
    try:
        print("🔍 Testing complete authentication flow...")
        
        # Step 1: Register a test user
        print("\n1. Registering test user...")
        register_data = {
            'email': 'testuser@example.com',
            'password': 'password123',
            'first_name': 'Test',
            'last_name': 'User',
            'user_type': 'farmer',
            'phone': '+94 77 123 4567',
            'location': 'Colombo'
        }
        
        response = requests.post(
            'http://localhost:8001/auth/register',
            headers={'Content-Type': 'application/json'},
            json=register_data,
            timeout=10
        )
        
        print(f"Registration Status: {response.status_code}")
        if response.status_code == 200:
            print("✅ User registered successfully")
        elif response.status_code == 400 and "already exists" in response.text:
            print("ℹ️ User already exists, continuing with login...")
        else:
            print(f"❌ Registration failed: {response.text}")
            return
        
        # Step 2: Login
        print("\n2. Logging in...")
        login_data = {
            'email': 'testuser@example.com',
            'password': 'password123'
        }
        
        response = requests.post(
            'http://localhost:8001/auth/login',
            headers={'Content-Type': 'application/json'},
            json=login_data,
            timeout=10
        )
        
        if response.status_code == 200:
            data = response.json()
            token = data.get('access_token')
            user = data.get('user')
            print(f"✅ Login successful!")
            print(f"   User ID: {user.get('uid')}")
            print(f"   User Type: {user.get('user_type')}")
            print(f"   Token length: {len(token) if token else 0}")
            
            if token:
                # Step 3: Test profile endpoint
                print("\n3. Testing profile endpoint...")
                headers = {
                    'Content-Type': 'application/json',
                    'Authorization': f'Bearer {token}'
                }
                
                response = requests.get(
                    'http://localhost:8001/profile/',
                    headers=headers,
                    timeout=10
                )
                
                print(f"Profile endpoint Status: {response.status_code}")
                if response.status_code == 200:
                    print("✅ Profile endpoint working!")
                else:
                    print(f"❌ Profile endpoint failed: {response.text}")
                
                # Step 4: Test image upload endpoint
                print("\n4. Testing image upload endpoint...")
                response = requests.get(
                    'http://localhost:8001/profile/upload-image',
                    headers=headers,
                    timeout=10
                )
                
                print(f"Image upload endpoint Status: {response.status_code}")
                if response.status_code == 405:  # Method Not Allowed is expected for GET
                    print("✅ Image upload endpoint exists!")
                elif response.status_code == 404:
                    print("❌ Image upload endpoint not found")
                else:
                    print(f"⚠️ Unexpected response: {response.status_code} - {response.text}")
            else:
                print("❌ No token received from login")
        else:
            print(f"❌ Login failed: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"❌ Error during test: {e}")

if __name__ == '__main__':
    test_complete_auth_flow()
