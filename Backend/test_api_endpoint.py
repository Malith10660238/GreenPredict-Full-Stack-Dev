#!/usr/bin/env python3
"""
Test script to verify API endpoint integration
"""
import requests
import json

def test_api_endpoint():
    """Test the prediction API endpoint"""
    print("🌐 Testing API Endpoint Integration...")
    print("=" * 50)
    
    # Test data matching the image example
    test_data = {
        'planning_year': '2025',
        'location': 'Colombo',
        'season': 'Yala',
        'temperature': '28.4',
        'soil_type': 'Latosols',
        'land_area': '1.0',
        'crop': 'Cabbage'
    }
    
    url = 'http://localhost:8001/predictions/test-analyze'
    
    try:
        print("1. Sending request to API endpoint...")
        response = requests.post(url, json=test_data, timeout=30)
        
        print(f"   Status Code: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ API Test PASSED!")
            print(f"   Prediction ID: {result.get('prediction_id', 'N/A')}")
            
            if 'result' in result:
                rec = result['result']['current_season_recommendation']
                print(f"   Decision: {rec['recommended_crop']}")
                print(f"   Success Rate: {rec['suitability_score']}%")
                
                # Check alternative crops
                alternatives = result['result'].get('alternative_crops', [])
                print(f"   Alternative Crops: {len(alternatives)} suggestions")
                
                # Check upcoming seasons
                seasons = result['result'].get('best_upcoming_seasons', [])
                print(f"   Upcoming Seasons: {len(seasons)} analyzed")
                
                return True
            else:
                print("❌ No result data in response")
                return False
        else:
            print(f"❌ API Test FAILED: {response.text}")
            return False
            
    except requests.exceptions.ConnectionError:
        print("❌ Connection Error: Could not connect to server")
        print("   Make sure the backend server is running on port 8001")
        print("   Run: python main_firebase.py")
        return False
    except Exception as e:
        print(f"❌ Unexpected Error: {e}")
        return False

def test_multiple_scenarios():
    """Test multiple prediction scenarios"""
    print("\n🧪 Testing Multiple Scenarios...")
    print("=" * 50)
    
    scenarios = [
        {
            'name': 'High Success Scenario',
            'data': {
                'planning_year': '2025',
                'location': 'Kandy',
                'season': 'Maha',
                'temperature': '25.0',
                'soil_type': 'Red-Yellow Podzolic Soils',
                'land_area': '2.0',
                'crop': 'Tea'
            }
        },
        {
            'name': 'Medium Success Scenario',
            'data': {
                'planning_year': '2025',
                'location': 'Galle',
                'season': 'Yala',
                'temperature': '27.0',
                'soil_type': 'Alluvial Soils',
                'land_area': '1.5',
                'crop': 'Coconut'
            }
        },
        {
            'name': 'Low Success Scenario',
            'data': {
                'planning_year': '2025',
                'location': 'Nuwara Eliya',
                'season': 'Yala',
                'temperature': '15.0',
                'soil_type': 'Latosols',
                'land_area': '1.0',
                'crop': 'Paddy'
            }
        }
    ]
    
    url = 'http://localhost:8001/predictions/test-analyze'
    passed = 0
    
    for i, scenario in enumerate(scenarios, 1):
        print(f"\n{i}. {scenario['name']}")
        try:
            response = requests.post(url, json=scenario['data'], timeout=30)
            if response.status_code == 200:
                result = response.json()
                if 'result' in result:
                    rec = result['result']['current_season_recommendation']
                    print(f"   ✅ Success Rate: {rec['suitability_score']}%")
                    passed += 1
                else:
                    print(f"   ❌ No result data")
            else:
                print(f"   ❌ Failed: {response.status_code}")
        except Exception as e:
            print(f"   ❌ Error: {e}")
    
    print(f"\n📊 Scenarios Test Results: {passed}/{len(scenarios)} passed")
    return passed == len(scenarios)

if __name__ == "__main__":
    print("🚀 Starting API Integration Tests...")
    print("=" * 60)
    
    # Test basic endpoint
    api_success = test_api_endpoint()
    
    if api_success:
        # Test multiple scenarios
        scenarios_success = test_multiple_scenarios()
        
        if scenarios_success:
            print("\n🎉 ALL API TESTS PASSED!")
            print("✅ Backend AI integration is working correctly")
            print("✅ API endpoints are responding properly")
            print("✅ Multiple scenarios are handled correctly")
        else:
            print("\n⚠️  Basic API test passed, but some scenarios failed")
    else:
        print("\n💥 API TESTS FAILED!")
        print("❌ Backend server may not be running")
        print("❌ Check if main_firebase.py is running on port 8001")
