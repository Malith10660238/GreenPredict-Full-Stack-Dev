from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class InputParameters(BaseModel):
    """Input parameters for AI prediction"""
    planning_year: str
    location: str
    season: str
    temperature: str
    soil_type: str
    land_area: str
    crop: str

class CurrentSeasonRecommendation(BaseModel):
    """Current season recommendation"""
    recommended_crop: str
    suitability_score: int
    reasons: List[str]
    planting_tips: List[str]

class SeasonRecommendation(BaseModel):
    """Season recommendation"""
    season: str
    suitability_score: int
    expected_yield: str
    profitability_rating: str

class YieldProfitabilityAnalysis(BaseModel):
    """Yield and profitability analysis"""
    expected_yield: str
    estimated_revenue: str
    estimated_costs: str
    net_profit: str
    profit_margin: str
    break_even_time: str

class RiskAssessment(BaseModel):
    """Risk assessment"""
    overall_risk: str
    weather_risk: str
    market_risk: str
    pest_disease_risk: str
    recommendations: List[str]

class AlternativeCrop(BaseModel):
    """Alternative crop suggestion"""
    name: str
    suitability_score: int
    expected_profit: str
    growth_period: str

class AIPredictionResult(BaseModel):
    """Complete AI prediction result"""
    input_parameters: InputParameters
    current_season_recommendation: CurrentSeasonRecommendation
    best_upcoming_seasons: List[SeasonRecommendation]
    yield_profitability_analysis: YieldProfitabilityAnalysis
    risk_assessment: RiskAssessment
    alternative_crops: List[AlternativeCrop]

class PredictionRequest(BaseModel):
    """Prediction request model"""
    planning_year: str
    location: str
    season: str
    temperature: str
    soil_type: str
    land_area: str
    crop: str

class PredictionResponse(BaseModel):
    """Prediction response model"""
    prediction_id: str
    result: AIPredictionResult
    created_at: datetime
    user_id: Optional[str] = None

class PredictionHistory(BaseModel):
    """Prediction history model"""
    prediction_id: str
    user_id: str
    input_parameters: InputParameters
    created_at: datetime
