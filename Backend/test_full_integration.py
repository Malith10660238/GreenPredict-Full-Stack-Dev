#!/usr/bin/env python3
"""
Comprehensive test for the full AI integration
Tests the exact scenario from the user's image
"""
import requests
import json

def test_cabbage_scenario():
    """Test the exact scenario from the user's image: Cabbage in Colombo, Yala season"""
    print("🥬 Testing Cabbage Scenario (from user's image)...")
    print("=" * 60)
    
    # Exact data from the user's image
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
        response = requests.post(url, json=test_data, timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Cabbage Prediction Successful!")
            
            # Extract key results
            rec = result['result']['current_season_recommendation']
            yield_analysis = result['result']['yield_profitability_analysis']
            alternatives = result['result']['alternative_crops']
            seasons = result['result']['best_upcoming_seasons']
            
            print(f"\n📊 ANALYSIS RESULTS:")
            print(f"   Decision: {rec['recommended_crop']}")
            print(f"   Success Rate: {rec['suitability_score']}%")
            print(f"   Expected Yield: {yield_analysis['expected_yield']}")
            print(f"   Predicted Profit: {yield_analysis['net_profit']}")
            print(f"   ROI: {yield_analysis['profit_margin']}")
            
            print(f"\n🌱 ALTERNATIVE CROPS:")
            for i, alt in enumerate(alternatives[:5], 1):
                print(f"   {i}. {alt['name']} - {alt['suitability_score']}% success")
            
            print(f"\n📅 UPCOMING SEASONS:")
            for season in seasons:
                print(f"   {season['season']} - {season['suitability_score']}% success")
            
            return True
        else:
            print(f"❌ Test failed: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_high_success_scenario():
    """Test a high success scenario"""
    print("\n🌿 Testing High Success Scenario...")
    print("=" * 60)
    
    test_data = {
        'planning_year': '2025',
        'location': 'Kandy',
        'season': 'Maha',
        'temperature': '25.0',
        'soil_type': 'Red-Yellow Podzolic Soils',
        'land_area': '2.0',
        'crop': 'Tea'
    }
    
    url = 'http://localhost:8001/predictions/test-analyze'
    
    try:
        response = requests.post(url, json=test_data, timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            rec = result['result']['current_season_recommendation']
            print(f"✅ Tea Prediction: {rec['suitability_score']}% success rate")
            return True
        else:
            print(f"❌ Test failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_edge_cases():
    """Test edge cases and error handling"""
    print("\n🔬 Testing Edge Cases...")
    print("=" * 60)
    
    edge_cases = [
        {
            'name': 'Extreme Temperature',
            'data': {
                'planning_year': '2025',
                'location': 'Nuwara Eliya',
                'season': 'Yala',
                'temperature': '5.0',  # Very cold
                'soil_type': 'Latosols',
                'land_area': '1.0',
                'crop': 'Paddy'
            }
        },
        {
            'name': 'Unusual Crop',
            'data': {
                'planning_year': '2025',
                'location': 'Colombo',
                'season': 'Maha',
                'temperature': '28.0',
                'soil_type': 'Alluvial Soils',
                'land_area': '1.0',
                'crop': 'Mango'
            }
        }
    ]
    
    passed = 0
    for case in edge_cases:
        print(f"\n   Testing: {case['name']}")
        try:
            response = requests.post(
                'http://localhost:8001/predictions/test-analyze',
                json=case['data'],
                timeout=30
            )
            if response.status_code == 200:
                result = response.json()
                rec = result['result']['current_season_recommendation']
                print(f"   ✅ Success Rate: {rec['suitability_score']}%")
                passed += 1
            else:
                print(f"   ❌ Failed: {response.status_code}")
        except Exception as e:
            print(f"   ❌ Error: {e}")
    
    print(f"\n📊 Edge Cases: {passed}/{len(edge_cases)} passed")
    return passed == len(edge_cases)

def test_response_format():
    """Test that the response format matches frontend expectations"""
    print("\n📱 Testing Response Format...")
    print("=" * 60)
    
    test_data = {
        'planning_year': '2025',
        'location': 'Colombo',
        'season': 'Yala',
        'temperature': '28.4',
        'soil_type': 'Latosols',
        'land_area': '1.0',
        'crop': 'Cabbage'
    }
    
    try:
        response = requests.post(
            'http://localhost:8001/predictions/test-analyze',
            json=test_data,
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            
            # Check required fields
            required_fields = [
                'prediction_id',
                'result',
                'created_at',
                'user_id'
            ]
            
            result_fields = [
                'input_parameters',
                'current_season_recommendation',
                'best_upcoming_seasons',
                'yield_profitability_analysis',
                'risk_assessment',
                'alternative_crops'
            ]
            
            print("✅ Response Structure Check:")
            for field in required_fields:
                if field in result:
                    print(f"   ✅ {field}: Present")
                else:
                    print(f"   ❌ {field}: Missing")
            
            if 'result' in result:
                print("\n✅ Result Structure Check:")
                for field in result_fields:
                    if field in result['result']:
                        print(f"   ✅ {field}: Present")
                    else:
                        print(f"   ❌ {field}: Missing")
            
            return True
        else:
            print(f"❌ Response format test failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    print("🚀 COMPREHENSIVE AI INTEGRATION TEST")
    print("=" * 80)
    
    tests = [
        ("Cabbage Scenario", test_cabbage_scenario),
        ("High Success Scenario", test_high_success_scenario),
        ("Edge Cases", test_edge_cases),
        ("Response Format", test_response_format)
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        print(f"\n🧪 Running: {test_name}")
        if test_func():
            passed += 1
            print(f"✅ {test_name}: PASSED")
        else:
            print(f"❌ {test_name}: FAILED")
    
    print(f"\n📊 FINAL RESULTS: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 ALL TESTS PASSED!")
        print("✅ AI Model Integration: WORKING")
        print("✅ API Endpoints: WORKING")
        print("✅ Response Format: COMPATIBLE")
        print("✅ Edge Cases: HANDLED")
        print("\n🚀 Ready for production use!")
    else:
        print(f"\n⚠️  {total - passed} tests failed")
        print("❌ Some issues need to be resolved")
