import requests
import json

def test_image_upload_endpoint():
    """Test if the image upload endpoint is available"""
    try:
        print("🔍 Testing image upload endpoint...")
        
        # First, login to get a token
        login_data = {
            'email': 'farmer@test.com',
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
            print(f"✅ Login successful! Token length: {len(token) if token else 0}")
            
            if token:
                # Test if the image upload endpoint exists
                headers = {
                    'Content-Type': 'application/json',
                    'Authorization': f'Bearer {token}'
                }
                
                # Make a GET request to test if endpoint exists (should return 405 Method Not Allowed)
                response = requests.get(
                    'http://localhost:8001/profile/upload-image',
                    headers=headers,
                    timeout=10
                )
                
                print(f"📊 Image upload endpoint GET Status: {response.status_code}")
                print(f"📊 Response: {response.text}")
                
                if response.status_code == 405:
                    print("✅ Image upload endpoint exists (405 Method Not Allowed is expected for GET)")
                elif response.status_code == 404:
                    print("❌ Image upload endpoint not found (404 Not Found)")
                else:
                    print(f"⚠️ Unexpected response: {response.status_code}")
            else:
                print("❌ No token received from login")
        else:
            print(f"❌ Login failed: {response.status_code}")
            print(f"Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Error during test: {e}")

if __name__ == '__main__':
    test_image_upload_endpoint()

