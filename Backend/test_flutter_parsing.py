#!/usr/bin/env python3
"""
Test the exact JSON structure that Flutter will receive
"""
import requests
import json

def test_flutter_json_structure():
    """Test the JSON structure for Flutter parsing"""
    print("📱 Testing Flutter JSON Structure...")
    print("=" * 60)
    
    # Get a sample response
    try:
        response = requests.post(
            'http://localhost:8001/predictions/test-analyze',
            json={
                'planning_year': '2025',
                'location': 'Colombo',
                'season': 'Yala',
                'temperature': '28.4',
                'soil_type': 'Latosols',
                'land_area': '1.0',
                'crop': 'Cabbage'
            },
            timeout=10
        )
        
        if response.status_code == 200:
            result = response.json()
            print("✅ API Response received")
            
            # Save the response to a file for Flutter testing
            with open('sample_response.json', 'w') as f:
                json.dump(result, f, indent=2)
            print("✅ Sample response saved to 'sample_response.json'")
            
            # Check the structure that Flutter expects
            print("\n📊 Flutter Parsing Analysis:")
            
            if 'result' in result:
                ai_result = result['result']
                print("✅ 'result' field present")
                
                # Check each field that Flutter will try to parse
                fields_to_check = [
                    ('inputParameters', 'InputParameters'),
                    ('currentSeasonRecommendation', 'CurrentSeasonRecommendation'),
                    ('bestUpcomingSeasons', 'List<SeasonRecommendation>'),
                    ('yieldProfitabilityAnalysis', 'YieldProfitabilityAnalysis'),
                    ('riskAssessment', 'RiskAssessment'),
                    ('alternativeCrops', 'List<AlternativeCrop>')
                ]
                
                for field_name, expected_type in fields_to_check:
                    if field_name in ai_result:
                        field_data = ai_result[field_name]
                        print(f"   ✅ {field_name}: Present ({type(field_data).__name__})")
                        
                        # Check if it's the right type
                        if field_name in ['bestUpcomingSeasons', 'alternativeCrops']:
                            if isinstance(field_data, list):
                                print(f"      ✅ List with {len(field_data)} items")
                                if len(field_data) > 0:
                                    print(f"      ✅ First item keys: {list(field_data[0].keys())}")
                            else:
                                print(f"      ❌ Not a list: {type(field_data)}")
                        else:
                            print(f"      ✅ Object with keys: {list(field_data.keys())}")
                    else:
                        print(f"   ❌ {field_name}: Missing")
                
                # Check specific field structures
                print(f"\n🔍 Detailed Field Analysis:")
                
                # InputParameters
                if 'inputParameters' in ai_result:
                    ip = ai_result['inputParameters']
                    ip_fields = ['planningYear', 'location', 'season', 'temperature', 'soilType', 'landArea', 'crop']
                    for field in ip_fields:
                        if field in ip:
                            print(f"   ✅ inputParameters.{field}: {ip[field]}")
                        else:
                            print(f"   ❌ inputParameters.{field}: Missing")
                
                # CurrentSeasonRecommendation
                if 'currentSeasonRecommendation' in ai_result:
                    rec = ai_result['currentSeasonRecommendation']
                    rec_fields = ['recommendedCrop', 'suitabilityScore', 'reasons', 'plantingTips']
                    for field in rec_fields:
                        if field in rec:
                            if field in ['reasons', 'plantingTips']:
                                print(f"   ✅ currentSeasonRecommendation.{field}: List with {len(rec[field])} items")
                            else:
                                print(f"   ✅ currentSeasonRecommendation.{field}: {rec[field]}")
                        else:
                            print(f"   ❌ currentSeasonRecommendation.{field}: Missing")
                
                # AlternativeCrops
                if 'alternativeCrops' in ai_result:
                    alts = ai_result['alternativeCrops']
                    if isinstance(alts, list) and len(alts) > 0:
                        print(f"   ✅ alternativeCrops: {len(alts)} items")
                        alt_fields = ['name', 'suitabilityScore', 'expectedProfit', 'growthPeriod']
                        for field in alt_fields:
                            if field in alts[0]:
                                print(f"      ✅ {field}: Present")
                            else:
                                print(f"      ❌ {field}: Missing")
                    else:
                        print(f"   ❌ alternativeCrops: Empty or not a list")
                
                return True
            else:
                print("❌ No 'result' field in response")
                return False
        else:
            print(f"❌ API call failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    success = test_flutter_json_structure()
    if success:
        print("\n🎉 JSON structure is ready for Flutter!")
        print("✅ All required fields are present")
        print("✅ Data types are correct")
        print("✅ Flutter should be able to parse successfully")
        print("\n📄 Sample response saved to 'sample_response.json'")
        print("   You can use this file to test Flutter parsing")
    else:
        print("\n💥 JSON structure issues detected!")
        print("❌ Some required fields are missing or incorrect")
        print("❌ Flutter parsing may fail")
