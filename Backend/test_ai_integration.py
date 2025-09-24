#!/usr/bin/env python3
"""
Test script to verify AI model integration
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from ai_model_service import ai_service

def test_ai_model():
    """Test the AI model integration"""
    print("🤖 Testing AI Model Integration...")
    print("=" * 50)
    
    # Test loading the model
    print("1. Loading AI models...")
    success = ai_service.load_models()
    
    if not success:
        print("❌ Failed to load AI models!")
        return False
    
    print("✅ AI models loaded successfully!")
    
    # Test prediction
    print("\n2. Testing prediction...")
    try:
        result = ai_service.predict_crop_recommendation(
            district="Colombo",
            soil_type="Latosols", 
            season="Yala",
            crop_name="Cabbage",
            temperature=28.4,
            land_area=1.0
        )
        
        print("✅ Prediction successful!")
        print(f"   Decision: {result['recommendation']['decision']}")
        print(f"   Success Probability: {result['recommendation']['success_probability']:.1f}%")
        print(f"   Expected Yield: {result['yield_profitability']['yield_per_hectare']:,} kg/ha")
        print(f"   Predicted Profit: LKR {result['yield_profitability']['predicted_profit']:,}")
        print(f"   Risk Assessment: {result['risk_assessment']}")
        print(f"   Alternative Crops: {len(result['alternatives'])} suggestions")
        
        return True
        
    except Exception as e:
        print(f"❌ Prediction failed: {e}")
        return False

if __name__ == "__main__":
    success = test_ai_model()
    if success:
        print("\n🎉 AI Model Integration Test PASSED!")
    else:
        print("\n💥 AI Model Integration Test FAILED!")
        sys.exit(1)
