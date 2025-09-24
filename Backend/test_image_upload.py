import requests
import json
import os
from PIL import Image
import io

def create_test_image():
    """Create a small test image"""
    # Create a simple 100x100 red image
    img = Image.new('RGB', (100, 100), color='red')
    img_bytes = io.BytesIO()
    img.save(img_bytes, format='JPEG')
    img_bytes.seek(0)
    return img_bytes.getvalue()

def test_image_upload():
    """Test image upload functionality"""
    try:
        print("🔍 Testing image upload functionality...")
        
        # Step 1: Login
        print("\n1. Logging in...")
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
        
        if response.status_code != 200:
            print(f"❌ Login failed: {response.status_code} - {response.text}")
            return
        
        data = response.json()
        token = data.get('access_token')
        print(f"✅ Login successful! Token length: {len(token) if token else 0}")
        
        if not token:
            print("❌ No token received")
            return
        
        # Step 2: Create test image
        print("\n2. Creating test image...")
        image_data = create_test_image()
        print(f"✅ Test image created, size: {len(image_data)} bytes")
        
        # Step 3: Upload image
        print("\n3. Uploading image...")
        headers = {
            'Authorization': f'Bearer {token}'
        }
        
        files = {
            'file': ('test_image.jpg', image_data, 'image/jpeg')
        }
        
        response = requests.post(
            'http://localhost:8001/profile/upload-image',
            headers=headers,
            files=files,
            timeout=30
        )
        
        print(f"Upload Status: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Image upload successful!")
            print(f"   Image URL: {result.get('image_url', 'Not provided')}")
        else:
            print("❌ Image upload failed")
            
    except Exception as e:
        print(f"❌ Error during test: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    test_image_upload()
