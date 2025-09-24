#!/usr/bin/env python3
"""
Test if the backend is accessible from frontend
"""
import requests
import json

def test_backend_connection():
    """Test if backend is accessible"""
    print("🔗 Testing Backend Connection...")
    print("=" * 50)
    
    # Test health endpoint
    try:
        response = requests.get('http://localhost:8001/health', timeout=5)
        if response.status_code == 200:
            print("✅ Health endpoint: WORKING")
        else:
            print(f"❌ Health endpoint: FAILED ({response.status_code})")
            return False
    except Exception as e:
        print(f"❌ Health endpoint: ERROR - {e}")
        return False
    
    # Test prediction endpoint
    try:
        url = 'http://localhost:8001/predictions/test-analyze'
        data = {
            'planning_year': '2025',
            'location': 'Colombo',
            'season': 'Yala',
            'temperature': '28.4',
            'soil_type': 'Latosols',
            'land_area': '1.0',
            'crop': 'Cabbage'
        }
        
        print(f"\n🧪 Testing prediction endpoint...")
        print(f"URL: {url}")
        print(f"Data: {data}")
        
        response = requests.post(url, json=data, timeout=10)
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Prediction endpoint: WORKING")
            print(f"Prediction ID: {result.get('prediction_id', 'N/A')}")
            
            if 'result' in result:
                rec = result['result']['current_season_recommendation']
                print(f"Crop: {rec['recommended_crop']}")
                print(f"Success Rate: {rec['suitability_score']}%")
                return True
            else:
                print("❌ No 'result' field in response")
                return False
        else:
            print(f"❌ Prediction endpoint: FAILED")
            print(f"Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Prediction endpoint: ERROR - {e}")
        return False

if __name__ == "__main__":
    success = test_backend_connection()
    if success:
        print("\n🎉 Backend is ready for frontend connection!")
        print("✅ All endpoints are working")
        print("✅ AI model is responding")
        print("✅ Data format is correct")
    else:
        print("\n💥 Backend connection issues detected!")
        print("❌ Check if backend server is running")
        print("❌ Check if AI model is loaded")
