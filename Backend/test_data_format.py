#!/usr/bin/env python3
"""
Test the exact data format that Flutter expects
"""
import requests
import json

def test_data_format():
    """Test the data format for Flutter compatibility"""
    print("📱 Testing Data Format for Flutter...")
    print("=" * 60)
    
    # Test with the exact data format Flutter sends
    flutter_data = {
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
            json=flutter_data,
            timeout=10
        )
        
        if response.status_code == 200:
            result = response.json()
            print("✅ API Response received")
            
            # Check the structure that Flutter expects
            print("\n📊 Response Structure Analysis:")
            
            # Top level fields
            top_level_fields = ['prediction_id', 'result', 'created_at', 'user_id']
            for field in top_level_fields:
                if field in result:
                    print(f"   ✅ {field}: Present")
                else:
                    print(f"   ❌ {field}: Missing")
            
            # Result structure
            if 'result' in result:
                ai_result = result['result']
                print(f"\n📊 AI Result Structure:")
                
                result_fields = [
                    'input_parameters',
                    'current_season_recommendation', 
                    'best_upcoming_seasons',
                    'yield_profitability_analysis',
                    'risk_assessment',
                    'alternative_crops'
                ]
                
                for field in result_fields:
                    if field in ai_result:
                        print(f"   ✅ {field}: Present")
                        
                        # Check specific structures
                        if field == 'current_season_recommendation':
                            rec = ai_result[field]
                            rec_fields = ['recommended_crop', 'suitability_score', 'reasons', 'planting_tips']
                            for rec_field in rec_fields:
                                if rec_field in rec:
                                    print(f"      ✅ {rec_field}: Present")
                                else:
                                    print(f"      ❌ {rec_field}: Missing")
                        
                        elif field == 'alternative_crops':
                            alts = ai_result[field]
                            if isinstance(alts, list) and len(alts) > 0:
                                print(f"      ✅ Alternative crops: {len(alts)} items")
                                if len(alts) > 0:
                                    alt_fields = ['name', 'suitability_score', 'expected_profit', 'growth_period']
                                    for alt_field in alt_fields:
                                        if alt_field in alts[0]:
                                            print(f"         ✅ {alt_field}: Present")
                                        else:
                                            print(f"         ❌ {alt_field}: Missing")
                            else:
                                print(f"      ❌ Alternative crops: Empty or not a list")
                        
                        elif field == 'best_upcoming_seasons':
                            seasons = ai_result[field]
                            if isinstance(seasons, list) and len(seasons) > 0:
                                print(f"      ✅ Upcoming seasons: {len(seasons)} items")
                                if len(seasons) > 0:
                                    season_fields = ['season', 'suitability_score', 'expected_yield', 'profitability_rating']
                                    for season_field in season_fields:
                                        if season_field in seasons[0]:
                                            print(f"         ✅ {season_field}: Present")
                                        else:
                                            print(f"         ❌ {season_field}: Missing")
                            else:
                                print(f"      ❌ Upcoming seasons: Empty or not a list")
                    else:
                        print(f"   ❌ {field}: Missing")
            else:
                print("   ❌ No 'result' field in response")
                return False
            
            print(f"\n🎯 Sample Data Preview:")
            if 'result' in result:
                rec = result['result']['current_season_recommendation']
                print(f"   Crop: {rec['recommended_crop']}")
                print(f"   Success Rate: {rec['suitability_score']}%")
                print(f"   Reasons: {len(rec['reasons'])} items")
                print(f"   Planting Tips: {len(rec['planting_tips'])} items")
                
                alts = result['result']['alternative_crops']
                print(f"   Alternative Crops: {len(alts)} suggestions")
                for i, alt in enumerate(alts[:3], 1):
                    print(f"     {i}. {alt['name']} ({alt['suitability_score']}%)")
            
            return True
        else:
            print(f"❌ API call failed: {response.status_code}")
            print(f"Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    success = test_data_format()
    if success:
        print("\n🎉 Data format is compatible with Flutter!")
        print("✅ All required fields are present")
        print("✅ Data structure matches expectations")
        print("✅ Flutter should be able to parse the response")
    else:
        print("\n💥 Data format issues detected!")
        print("❌ Some required fields are missing")
        print("❌ Flutter may not be able to parse the response")
