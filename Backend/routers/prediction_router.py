from fastapi import APIRouter, HTTPException, Depends, status
from firebase_admin import firestore
from typing import Dict, Any, List
import uuid
from datetime import datetime

from models.prediction import (
    PredictionRequest, 
    PredictionResponse, 
    AIPredictionResult,
    InputParameters,
    CurrentSeasonRecommendation,
    SeasonRecommendation,
    YieldProfitabilityAnalysis,
    RiskAssessment,
    AlternativeCrop,
    PredictionHistory
)
from auth_dependencies import get_current_user
from ai_model_service import ai_service

def convert_to_camel_case(data):
    """Convert snake_case keys to camelCase for Flutter compatibility"""
    if isinstance(data, dict):
        return {to_camel_case(key): convert_to_camel_case(value) for key, value in data.items()}
    elif isinstance(data, list):
        return [convert_to_camel_case(item) for item in data]
    else:
        return data

def to_camel_case(snake_str):
    """Convert snake_case string to camelCase"""
    components = snake_str.split('_')
    return components[0] + ''.join(x.capitalize() for x in components[1:])

router = APIRouter()

@router.post("/test-analyze", response_model=PredictionResponse)
async def test_analyze_crop_prediction(prediction_data: PredictionRequest):
    """Test endpoint for crop prediction analysis (no authentication required)"""
    try:
        db = firestore.client()
        
        # Generate prediction ID
        prediction_id = str(uuid.uuid4())
        
        # Create input parameters object
        input_params = InputParameters(
            planning_year=prediction_data.planning_year,
            location=prediction_data.location,
            season=prediction_data.season,
            temperature=prediction_data.temperature,
            soil_type=prediction_data.soil_type,
            land_area=prediction_data.land_area,
            crop=prediction_data.crop
        )
        
        # Generate AI prediction result using the trained model
        prediction_result = generate_ai_prediction(input_params)
        
        # Save prediction to Firestore (optional for test)
        try:
            prediction_doc = {
                'prediction_id': prediction_id,
                'user_id': 'test_user',
                'input_parameters': input_params.dict(),
                'result': prediction_result.dict(),
                'created_at': datetime.now()
            }
            db.collection('predictions').document(prediction_id).set(prediction_doc)
        except Exception as e:
            print(f"Warning: Could not save to Firestore: {e}")
        
        return PredictionResponse(
            prediction_id=prediction_id,
            result=prediction_result,
            created_at=datetime.now(),
            user_id='test_user'
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Prediction analysis failed: {str(e)}"
        )

@router.post("/analyze", response_model=PredictionResponse)
async def analyze_crop_prediction(
    prediction_data: PredictionRequest,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Analyze crop prediction based on input parameters"""
    try:
        db = firestore.client()
        
        # Generate prediction ID
        prediction_id = str(uuid.uuid4())
        
        # Create input parameters object
        input_params = InputParameters(
            planning_year=prediction_data.planning_year,
            location=prediction_data.location,
            season=prediction_data.season,
            temperature=prediction_data.temperature,
            soil_type=prediction_data.soil_type,
            land_area=prediction_data.land_area,
            crop=prediction_data.crop
        )
        
        # Generate AI prediction result using the trained model
        prediction_result = generate_ai_prediction(input_params)
        
        # Save prediction to Firestore
        prediction_doc = {
            'prediction_id': prediction_id,
            'user_id': current_user['uid'],
            'input_parameters': input_params.dict(),
            'result': prediction_result.dict(),
            'created_at': datetime.now()
        }
        
        db.collection('predictions').document(prediction_id).set(prediction_doc)
        
        return PredictionResponse(
            prediction_id=prediction_id,
            result=prediction_result,
            created_at=datetime.now(),
            user_id=current_user['uid']
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Prediction analysis failed: {str(e)}"
        )

@router.get("/history", response_model=List[PredictionHistory])
async def get_prediction_history(
    current_user: Dict[str, Any] = Depends(get_current_user),
    limit: int = 10,
    offset: int = 0
):
    """Get user's prediction history"""
    try:
        db = firestore.client()
        
        # Query user's predictions
        predictions_query = (
            db.collection('predictions')
            .where('user_id', '==', current_user['uid'])
            .order_by('created_at', direction=firestore.Query.DESCENDING)
            .limit(limit)
            .offset(offset)
        )
        
        predictions = predictions_query.stream()
        
        prediction_history = []
        for pred in predictions:
            pred_data = pred.to_dict()
            prediction_history.append(PredictionHistory(
                prediction_id=pred_data['prediction_id'],
                user_id=pred_data['user_id'],
                input_parameters=InputParameters(**pred_data['input_parameters']),
                created_at=pred_data['created_at']
            ))
        
        return prediction_history
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch prediction history: {str(e)}"
        )

@router.get("/{prediction_id}", response_model=PredictionResponse)
async def get_prediction_by_id(
    prediction_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Get specific prediction by ID"""
    try:
        db = firestore.client()
        
        # Get prediction document
        pred_doc = db.collection('predictions').document(prediction_id).get()
        
        if not pred_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Prediction not found"
            )
        
        pred_data = pred_doc.to_dict()
        
        # Check if user owns this prediction
        if pred_data['user_id'] != current_user['uid']:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied"
            )
        
        return PredictionResponse(
            prediction_id=pred_data['prediction_id'],
            result=AIPredictionResult(**pred_data['result']),
            created_at=pred_data['created_at'],
            user_id=pred_data['user_id']
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch prediction: {str(e)}"
        )

def generate_ai_prediction(input_params: InputParameters) -> AIPredictionResult:
    """Generate AI prediction result using the trained model"""
    
    # Convert string parameters to appropriate types
    try:
        temperature = float(input_params.temperature) if input_params.temperature and input_params.temperature != "null" else None
        land_area = float(input_params.land_area) if input_params.land_area else 1.0
    except (ValueError, TypeError):
        temperature = None
        land_area = 1.0
    
    # Get AI prediction from the model - let AI service use defaults when None
    ai_result = ai_service.predict_crop_recommendation(
        district=input_params.location,
        season=input_params.season,
        crop_name=input_params.crop,
        soil_type=input_params.soil_type if input_params.soil_type and input_params.soil_type != "null" else None,
        temperature=temperature,
        land_area=land_area
    )
    
    # Extract results
    recommendation = ai_result['recommendation']
    yield_profit = ai_result['yield_profitability']
    risk_assessment = ai_result['risk_assessment']
    alternatives = ai_result['alternatives']
    seasonal_analysis = ai_result['seasonal_analysis']
    
    # Get the actual values used by AI service (with defaults applied)
    actual_input_params = ai_result['input_params']
    actual_temperature = actual_input_params['temperature']
    actual_soil_type = actual_input_params['soil_type']
    
    # Create current season recommendation
    current_season = CurrentSeasonRecommendation(
        recommended_crop=input_params.crop,
        suitability_score=int(recommendation['success_probability']),
        reasons=[
            f"Success probability: {recommendation['success_probability']:.1f}%",
            f"Confidence level: {recommendation['confidence_level']}",
            f"Decision: {recommendation['decision']}",
            f"Expected yield: {yield_profit['yield_per_hectare']:,} kg/ha"
        ],
        planting_tips=[
            "Plant during optimal season timing",
            "Ensure proper soil preparation",
            "Monitor weather conditions regularly",
            "Use recommended fertilizers and pesticides"
        ]
    )
    
    # Create upcoming seasons
    upcoming_seasons = []
    for season_data in seasonal_analysis:
        upcoming_seasons.append(SeasonRecommendation(
            season=season_data['season'],
            suitability_score=int(season_data['success_percentage']),
            expected_yield=f"{season_data['yield_kg_per_ha']:,} kg/ha",
            profitability_rating="High" if season_data['profit_lkr_per_ha'] > 200000 else "Medium" if season_data['profit_lkr_per_ha'] > 100000 else "Low"
        ))
    
    # Create yield analysis
    yield_analysis = YieldProfitabilityAnalysis(
        expected_yield=f"{yield_profit['yield_per_hectare']:,} kg/ha",
        estimated_revenue=f"LKR {yield_profit['predicted_profit'] + yield_profit['estimated_cost']:,}",
        estimated_costs=f"LKR {yield_profit['estimated_cost']:,}",
        net_profit=f"LKR {yield_profit['predicted_profit']:,}",
        profit_margin=f"{yield_profit['roi']:.1f}%",
        break_even_time="6 months"
    )
    
    # Create risk assessment
    risk_level = "Low" if "Low risk" in risk_assessment else "Medium" if "Medium risk" in risk_assessment else "High"
    risk_assessment_obj = RiskAssessment(
        overall_risk=risk_level,
        weather_risk="Low" if recommendation['success_probability'] > 70 else "Medium" if recommendation['success_probability'] > 50 else "High",
        market_risk="Low" if yield_profit['predicted_profit'] > 0 else "High",
        pest_disease_risk="Low",
        recommendations=[
            "Monitor weather conditions regularly",
            "Implement proper irrigation systems",
            "Use disease-resistant varieties",
            "Follow integrated pest management practices"
        ]
    )
    
    # Create alternative crops
    alternative_crops = []
    for alt in alternatives:
        alternative_crops.append(AlternativeCrop(
            name=alt['crop_name'],
            suitability_score=int(alt['success_probability']),
            expected_profit=f"LKR {alt['profit_lkr_per_ha']:,}",
            growth_period="4-6 months"
        ))
    
    # Create InputParameters with actual values used by AI service
    actual_input_params = InputParameters(
        planning_year=input_params.planning_year,
        location=input_params.location,
        season=input_params.season,
        temperature=str(actual_temperature) if actual_temperature is not None else None,
        soil_type=actual_soil_type,
        land_area=input_params.land_area,
        crop=input_params.crop
    )
    
    return AIPredictionResult(
        input_parameters=actual_input_params,
        current_season_recommendation=current_season,
        best_upcoming_seasons=upcoming_seasons,
        yield_profitability_analysis=yield_analysis,
        risk_assessment=risk_assessment_obj,
        alternative_crops=alternative_crops
    )
