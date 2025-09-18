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

router = APIRouter()

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
        
        # Generate AI prediction result (mock implementation)
        # In a real application, this would call your ML model
        prediction_result = generate_mock_prediction(input_params)
        
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

def generate_mock_prediction(input_params: InputParameters) -> AIPredictionResult:
    """Generate mock prediction result (replace with actual ML model)"""
    
    # Mock current season recommendation
    current_season = CurrentSeasonRecommendation(
        recommended_crop=input_params.crop,
        suitability_score=85,
        reasons=[
            f"Optimal weather conditions for {input_params.crop} cultivation",
            f"High market demand in {input_params.location} region",
            f"Low pest risk during {input_params.season}",
            "Water availability is sufficient"
        ],
        planting_tips=[
            "Plant during early morning hours",
            "Ensure proper spacing between plants",
            "Use organic fertilizers for better yield",
            "Regular monitoring for pest control"
        ]
    )
    
    # Mock upcoming seasons
    upcoming_seasons = [
        SeasonRecommendation(
            season="Maha (October - March)",
            suitability_score=92,
            expected_yield="4.5 tons/acre",
            profitability_rating="High"
        ),
        SeasonRecommendation(
            season="Yala (April - September)",
            suitability_score=78,
            expected_yield="3.8 tons/acre",
            profitability_rating="Medium"
        )
    ]
    
    # Mock yield analysis
    yield_analysis = YieldProfitabilityAnalysis(
        expected_yield="4.2 tons/acre",
        estimated_revenue="Rs. 420,000/acre",
        estimated_costs="Rs. 180,000/acre",
        net_profit="Rs. 240,000/acre",
        profit_margin="57%",
        break_even_time="6 months"
    )
    
    # Mock risk assessment
    risk_assessment = RiskAssessment(
        overall_risk="Medium",
        weather_risk="Low",
        market_risk="Medium",
        pest_disease_risk="Low",
        recommendations=[
            "Consider crop insurance for weather protection",
            "Diversify with 2-3 different crops",
            "Monitor market prices regularly",
            "Implement IPM practices"
        ]
    )
    
    # Mock alternative crops
    alternative_crops = [
        AlternativeCrop(
            name="Tomatoes",
            suitability_score=88,
            expected_profit="Rs. 320,000/acre",
            growth_period="4 months"
        ),
        AlternativeCrop(
            name="Onions",
            suitability_score=82,
            expected_profit="Rs. 280,000/acre",
            growth_period="5 months"
        ),
        AlternativeCrop(
            name="Carrots",
            suitability_score=79,
            expected_profit="Rs. 260,000/acre",
            growth_period="3 months"
        ),
        AlternativeCrop(
            name="Cabbage",
            suitability_score=76,
            expected_profit="Rs. 240,000/acre",
            growth_period="3.5 months"
        ),
        AlternativeCrop(
            name="Lettuce",
            suitability_score=73,
            expected_profit="Rs. 200,000/acre",
            growth_period="2.5 months"
        )
    ]
    
    return AIPredictionResult(
        input_parameters=input_params,
        current_season_recommendation=current_season,
        best_upcoming_seasons=upcoming_seasons,
        yield_profitability_analysis=yield_analysis,
        risk_assessment=risk_assessment,
        alternative_crops=alternative_crops
    )
