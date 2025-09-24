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
        
        # Save prediction to Firestore in crop_predictions_ai collection
        prediction_doc = {
            'prediction_id': prediction_id,
            'user_id': current_user['uid'],
            'cropType': input_params.crop,
            'location': input_params.location,
            'predictedYield': prediction_result.yield_profitability_analysis.expected_yield,
            'confidence': prediction_result.current_season_recommendation.suitability_score / 100,
            'createdAt': datetime.now(),
            'input_parameters': input_params.dict(),
            'ai_analysis': {
                'input_parameters': {
                    'land_area': input_params.land_area,
                    'planning_year': input_params.planning_year,
                    'season': input_params.season,
                    'soil_type': input_params.soil_type,
                    'temperature': input_params.temperature
                },
                'current_season': {
                    'recommended_crop': input_params.crop,
                    'suitability_score': prediction_result.current_season_recommendation.suitability_score,
                    'reasons': prediction_result.current_season_recommendation.reasons,
                    'planting_tips': prediction_result.current_season_recommendation.planting_tips
                },
                'upcoming_seasons': [
                    {
                        'season': season.season,
                        'suitabilityScore': season.suitability_score,
                        'expectedYield': season.expected_yield,
                        'profitabilityRating': season.profitability_rating
                    } for season in prediction_result.best_upcoming_seasons
                ],
                'yield_analysis': {
                    'expected_yield': prediction_result.yield_profitability_analysis.expected_yield,
                    'estimated_costs': prediction_result.yield_profitability_analysis.estimated_costs,
                    'estimated_revenue': prediction_result.yield_profitability_analysis.estimated_revenue,
                    'net_profit': prediction_result.yield_profitability_analysis.net_profit,
                    'profit_margin': prediction_result.yield_profitability_analysis.profit_margin,
                    'break_even_time': prediction_result.yield_profitability_analysis.break_even_time
                },
                'risk_assessment': {
                    'overall_risk': prediction_result.risk_assessment.overall_risk,
                    'weather_risk': prediction_result.risk_assessment.weather_risk,
                    'market_risk': prediction_result.risk_assessment.market_risk,
                    'pest_disease_risk': prediction_result.risk_assessment.pest_disease_risk,
                    'recommendations': prediction_result.risk_assessment.recommendations
                },
                'alternative_crops': [
                    {
                        'name': crop.name,
                        'suitabilityScore': crop.suitability_score,
                        'expectedProfit': crop.expected_profit,
                        'growthPeriod': crop.growth_period
                    } for crop in prediction_result.alternative_crops
                ]
            }
        }
        
        db.collection('crop_predictions_ai').document(prediction_id).set(prediction_doc)
        
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

@router.get("/history", response_model=List[Dict[str, Any]])
async def get_prediction_history(
    current_user: Dict[str, Any] = Depends(get_current_user),
    limit: int = 10,
    offset: int = 0
):
    """Get user's prediction history from crop_predictions_ai collection"""
    try:
        print(f"🔵 Backend: Getting prediction history for user: {current_user['uid']}")
        db = firestore.client()
        
        # Query user's predictions from crop_predictions_ai collection
        # Note: This query requires a composite index on (user_id, createdAt)
        # Create index at: https://console.firebase.google.com/v1/r/project/green-predict/firestore/indexes
        
        # Use fallback query to avoid composite index requirement
        # Get all user predictions and sort manually in Python
        print("🔵 Backend: Using fallback query to avoid composite index requirement")
        predictions_query = (
            db.collection('crop_predictions_ai')
            .where('user_id', '==', current_user['uid'])
            .limit(50)  # Get more to account for manual sorting
        )
        
        predictions = predictions_query.stream()
        
        prediction_history = []
        prediction_count = 0
        for pred in predictions:
            prediction_count += 1
            print(f"🔵 Backend: Processing prediction {prediction_count}: {pred.id}")
            pred_data = pred.to_dict()
            # Convert Firestore timestamp to ISO string format
            created_at = pred_data.get('createdAt')
            if hasattr(created_at, 'timestamp'):
                created_at = datetime.fromtimestamp(created_at.timestamp()).isoformat()
            elif isinstance(created_at, datetime):
                created_at = created_at.isoformat()
            elif isinstance(created_at, str):
                # If it's already a string, keep it as is
                pass
            else:
                # Convert to ISO string format
                created_at = created_at.isoformat() if created_at else None
            
            prediction_history.append({
                'prediction_id': pred_data.get('prediction_id'),
                'user_id': pred_data.get('user_id'),
                'cropType': pred_data.get('cropType'),
                'location': pred_data.get('location'),
                'predictedYield': pred_data.get('predictedYield'),
                'confidence': pred_data.get('confidence'),
                'createdAt': created_at,
                'ai_analysis': pred_data.get('ai_analysis', {})
            })
        
        # Manual sorting for fallback query (no composite index)
        print(f"🔵 Backend: Sorting {len(prediction_history)} predictions manually")
        if len(prediction_history) > 1:
            # Sort by createdAt in descending order (newest first)
            prediction_history.sort(key=lambda x: x.get('createdAt', datetime.min), reverse=True)
        
        # Apply limit and offset manually
        print(f"🔵 Backend: Applying limit={limit}, offset={offset}")
        if len(prediction_history) > offset:
            prediction_history = prediction_history[offset:offset + limit]
        else:
            prediction_history = []
        
        print(f"🔵 Backend: Returning {len(prediction_history)} predictions to frontend")
        return prediction_history
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch prediction history: {str(e)}"
        )

@router.get("/{prediction_id}", response_model=Dict[str, Any])
async def get_prediction_by_id(
    prediction_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Get specific prediction by ID from crop_predictions_ai collection"""
    try:
        db = firestore.client()
        
        # Get prediction document from crop_predictions_ai collection
        pred_doc = db.collection('crop_predictions_ai').document(prediction_id).get()
        
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
        
        # Convert Firestore timestamp to datetime if needed
        created_at = pred_data.get('createdAt')
        if hasattr(created_at, 'timestamp'):
            created_at = datetime.fromtimestamp(created_at.timestamp())
        
        return {
            'prediction_id': pred_data.get('prediction_id'),
            'user_id': pred_data.get('user_id'),
            'cropType': pred_data.get('cropType'),
            'location': pred_data.get('location'),
            'predictedYield': pred_data.get('predictedYield'),
            'confidence': pred_data.get('confidence'),
            'createdAt': created_at,
            'ai_analysis': pred_data.get('ai_analysis', {})
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch prediction: {str(e)}"
        )

@router.delete("/{prediction_id}")
async def delete_prediction(
    prediction_id: str,
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Delete a specific prediction by ID"""
    try:
        print(f"🔵 Backend: Deleting prediction {prediction_id} for user: {current_user['uid']}")
        db = firestore.client()
        
        # Get prediction document to verify ownership
        pred_doc = db.collection('crop_predictions_ai').document(prediction_id).get()
        
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
        
        # Delete the prediction
        db.collection('crop_predictions_ai').document(prediction_id).delete()
        
        print(f"✅ Backend: Successfully deleted prediction {prediction_id}")
        return {"message": "Prediction deleted successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Backend: Error deleting prediction: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete prediction: {str(e)}"
        )

@router.delete("/")
async def delete_all_predictions(
    current_user: Dict[str, Any] = Depends(get_current_user)
):
    """Delete all predictions for the current user"""
    try:
        print(f"🔵 Backend: Deleting all predictions for user: {current_user['uid']}")
        db = firestore.client()
        
        # Get all user predictions
        predictions_query = (
            db.collection('crop_predictions_ai')
            .where('user_id', '==', current_user['uid'])
        )
        
        predictions = predictions_query.stream()
        deleted_count = 0
        
        # Delete each prediction
        for pred in predictions:
            pred.reference.delete()
            deleted_count += 1
        
        print(f"✅ Backend: Successfully deleted {deleted_count} predictions")
        return {
            "message": f"Successfully deleted {deleted_count} predictions",
            "deleted_count": deleted_count
        }
        
    except Exception as e:
        print(f"❌ Backend: Error deleting all predictions: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete predictions: {str(e)}"
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
