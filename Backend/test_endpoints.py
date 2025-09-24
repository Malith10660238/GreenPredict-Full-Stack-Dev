import requests
import json

def test_available_endpoints():
    """Test what endpoints are available"""
    try:
        print("🔍 Testing available endpoints...")
        
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
                headers = {
                    'Content-Type': 'application/json',
                    'Authorization': f'Bearer {token}'
                }
                
                # Test different endpoints
                endpoints_to_test = [
                    '/profile',
                    '/profile/',
                    '/profile/upload-image',
                    '/profile/upload-image/',
                    '/upload-image',
                    '/upload-image/',
                ]
                
                for endpoint in endpoints_to_test:
                    try:
                        response = requests.get(
                            f'http://localhost:8001{endpoint}',
                            headers=headers,
                            timeout=5
                        )
                        print(f"📊 {endpoint} - Status: {response.status_code}")
                        if response.status_code not in [404, 405]:
                            print(f"   Response: {response.text[:100]}...")
                    except Exception as e:
                        print(f"📊 {endpoint} - Error: {e}")
                        
        else:
            print(f"❌ Login failed: {response.status_code}")
            print(f"Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Error during test: {e}")

if __name__ == '__main__':
    test_available_endpoints()

