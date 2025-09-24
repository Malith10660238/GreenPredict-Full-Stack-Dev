"""
AI Model Service for GreenPredict
Integrates the trained .pkl model with the backend API
"""
import pandas as pd
import numpy as np
import pickle
import os
from typing import Dict, Any, List, Optional
import warnings
warnings.filterwarnings('ignore')

class GreenPredictAIService:
    def __init__(self):
        self.models = {}
        self.encoders = {}
        self.scaler = None
        self.feature_names = []
        self.crop_costs = {}
        self.df = None
        self._initialize_crop_costs()
        
    def _initialize_crop_costs(self):
        """Crop-specific cost estimates in LKR per hectare"""
        self.crop_costs = {
            'Paddy': 180000, 'Maize': 120000, 'Coconut': 200000, 'Tea': 250000,
            'Rubber': 300000, 'Cabbage': 160000, 'Carrot': 140000, 'Beans': 130000,
            'Tomato': 170000, 'Chili': 150000, 'Big Onion': 140000, 'Potato': 160000,
            'Sweet Potato': 100000, 'Manioc': 90000, 'Pumpkin': 80000, 'Brinjal': 150000,
            'Banana': 200000, 'Papaya': 180000, 'Mango': 220000
        }
    
    def load_models(self, model_path: str = 'green_predict_models.pkl'):
        """Load the trained models from pickle file"""
        try:
            if not os.path.exists(model_path):
                raise FileNotFoundError(f"Model file not found: {model_path}")
            
            with open(model_path, 'rb') as f:
                model_data = pickle.load(f)
            
            self.models = model_data['models']
            self.encoders = model_data['encoders']
            self.scaler = model_data['scaler']
            self.feature_names = model_data['feature_names']
            self.crop_costs = model_data.get('crop_costs', self.crop_costs)
            
            # Load the dataset for district averages and validation
            try:
                csv_path = 'sri_lanka_agri_data_improved.csv'
                if os.path.exists(csv_path):
                    self.df = pd.read_csv(csv_path)
                    self.df = self._prepare_features()
                    print(f"✅ Dataset loaded successfully")
                else:
                    print(f"⚠️  Warning: CSV file not found. Some features may not work properly.")
                    self.df = None
            except Exception as e:
                print(f"⚠️  Warning: Could not load dataset: {e}")
                self.df = None
            
            print(f"✅ AI models loaded successfully from '{model_path}'")
            return True
            
        except Exception as e:
            print(f"❌ Error loading models: {e}")
            return False
    
    def _prepare_features(self):
        """Prepare features for modeling (same as training)"""
        if self.df is None:
            return None
            
        df = self.df.copy()
        
        # Initialize encoders
        categorical_features = ['District', 'Soil_Type', 'Season', 'Crop_Name']
        
        for feature in categorical_features:
            if feature in self.encoders:
                df[f'{feature}_encoded'] = self.encoders[feature].transform(df[feature])
        
        # Feature engineering
        df['Temp_Rainfall_Interaction'] = df['Avg_Temperature_C'] * df['Total_Rainfall_mm']
        df['Humidity_Sunlight_Ratio'] = df['Avg_Humidity_Percent'] / (df['Sunlight_Hours_Per_Day'] + 1)
        df['Yield_Price_Product'] = df['Yield_kg_per_hectare'] * df['Avg_Market_Price_LKR_per_kg']
        
        return df
    
    def predict_crop_recommendation(self, 
                                   district: str, 
                                   season: str, 
                                   crop_name: str, 
                                   soil_type: Optional[str] = None, 
                                   temperature: Optional[float] = None, 
                                   rainfall: Optional[float] = None, 
                                   humidity: Optional[float] = None, 
                                   sunlight: Optional[float] = None, 
                                   land_area: float = 1.0) -> Dict[str, Any]:
        """Generate comprehensive crop recommendation using the AI model"""
        
        # Handle case when df is not loaded
        if self.df is None:
            print("⚠️  Warning: Dataset not available. Using default values.")
            # Use default values
            if temperature is None:
                district_defaults = {
                    'Ampara': 30.0, 'Anuradhapura': 30.0, 'Badulla': 21.5, 'Batticaloa': 29.4,
                    'Colombo': 28.4, 'Galle': 28.4, 'Gampaha': 28.5, 'Hambantota': 30.1,
                    'Jaffna': 30.8, 'Kalutara': 28.5, 'Kandy': 23.9, 'Kegalle': 27.5,
                    'Kilinochchi': 30.1, 'Kurunegala': 29.6, 'Mannar': 30.1, 'Matale': 25.9,
                    'Matara': 28.6, 'Monaragala': 29.1, 'Mullaitivu': 29.5, 'Nuwara Eliya': 15.0,
                    'Polonnaruwa': 30.0, 'Puttalam': 29.5, 'Ratnapura': 26.5, 'Trincomalee': 30.6,
                    'Vavuniya': 29.6
                }
                temperature = district_defaults.get(district, 27.5)
                print(f"🌡️  Using default temperature for {district}: {temperature}°C")
            if soil_type is None:
                district_soil_defaults = {
                    'Ampara': 'Reddish Brown Earths', 'Anuradhapura': 'Alluvial Soils', 
                    'Badulla': 'Red-Yellow Podzolic Soils', 'Batticaloa': 'Regosols',
                    'Colombo': 'Latosols', 'Galle': 'Latosols', 
                    'Gampaha': 'Latosols', 'Hambantota': 'Reddish Brown Earths',
                    'Jaffna': 'Regosols', 'Kalutara': 'Red-Yellow Podzolic Soils', 
                    'Kandy': 'Reddish Brown Earths', 'Kegalle': 'Latosols',
                    'Kilinochchi': 'Reddish Brown Earths', 'Kurunegala': 'Alluvial Soils', 
                    'Mannar': 'Regosols', 'Matale': 'Reddish Brown Earths',
                    'Matara': 'Alluvial Soils', 'Monaragala': 'Reddish Brown Earths', 
                    'Mullaitivu': 'Latosols', 'Nuwara Eliya': 'Red-Yellow Podzolic Soils',
                    'Polonnaruwa': 'Alluvial Soils', 'Puttalam': 'Calcic Red Latosols', 
                    'Ratnapura': 'Red-Yellow Podzolic Soils', 'Trincomalee': 'Alluvial Soils',
                    'Vavuniya': 'Reddish Brown Earths'
                }
                soil_type = district_soil_defaults.get(district, 'Latosols')
                print(f"🌱 Using default soil type for {district}: {soil_type}")
            if rainfall is None:
                rainfall = 1800.0
            if humidity is None:
                humidity = 75.0
            if sunlight is None:
                sunlight = 6.0
                
            district_min_temp = temperature - 8  # Estimate
            district_max_temp = temperature + 8  # Estimate
        else:
            # Get district averages if parameters not provided
            district_data = self.df[self.df['District'] == district]
            
            if temperature is None:
                temperature = round(district_data['Avg_Temperature_C'].mean(), 1)
                print(f"🌡️  Using district average temperature for {district}: {temperature}°C")
            if rainfall is None:
                rainfall = round(district_data['Total_Rainfall_mm'].mean(), 1)
            if humidity is None:
                humidity = round(district_data['Avg_Humidity_Percent'].mean(), 1)
            if sunlight is None:
                sunlight = round(district_data['Sunlight_Hours_Per_Day'].mean(), 1)
            if soil_type is None:
                # Get the most common soil type for this district
                soil_type = district_data['Soil_Type'].mode().iloc[0] if not district_data['Soil_Type'].mode().empty else 'Latosols'
                print(f"🌱 Using most common soil type for {district}: {soil_type}")
                
            # Get actual district temperature range
            district_min_temp = district_data['Avg_Temperature_C'].min()
            district_max_temp = district_data['Avg_Temperature_C'].max()
        
        # Calculate temperature penalty
        temperature_penalty = 0
        if temperature < district_min_temp - 5 or temperature > district_max_temp + 5:
            deviation = max(abs(temperature - district_min_temp), abs(temperature - district_max_temp)) - 5
            temperature_penalty = min(0.9, deviation * 0.1)  # Up to 90% penalty
            print(f"⚠️  Warning: {temperature}°C is outside normal range for {district} ({district_min_temp:.1f}°C - {district_max_temp:.1f}°C)")
        
        # Prepare input features
        input_data = self._prepare_input_features(district, soil_type, season, crop_name, temperature, rainfall, humidity, sunlight)
        
        # Make predictions
        success_prob = self.models['success_classifier'].predict_proba([input_data])[0]
        predicted_yield = self.models['yield_predictor'].predict([input_data])[0]
        predicted_price = self.models['price_predictor'].predict([input_data])[0]
        
        # Apply temperature penalty to predictions
        if temperature_penalty > 0:
            # Heavily reduce success probability for impossible temperatures
            success_prob[1] = success_prob[1] * (1 - temperature_penalty)  # Reduce "Recommended" probability
            success_prob[0] = 1 - success_prob[1]  # Adjust "Not Recommended" probability
            
            # Reduce yield for extreme temperatures
            predicted_yield = predicted_yield * (1 - temperature_penalty * 0.8)
        
        # Calculate profit
        cost = self.crop_costs.get(crop_name, 150000)
        total_yield = predicted_yield * land_area
        revenue = total_yield * predicted_price
        profit = revenue - (cost * land_area)
        roi = (profit / (cost * land_area)) * 100 if cost > 0 else 0
        
        # Risk assessment
        risk_level = self._assess_risk(success_prob[1], predicted_yield, profit, temperature_penalty)
        
        # Get alternative crop recommendations
        alternatives = self._get_alternative_crops(district, soil_type, season, temperature, rainfall, humidity, sunlight)
        
        # Generate seasonal analysis
        seasonal_analysis = self._generate_seasonal_analysis(district, soil_type, crop_name, temperature, rainfall, humidity, sunlight)
        
        return {
            'input_params': {
                'year': 2025,
                'district': district,
                'soil_type': soil_type,
                'season': season,
                'crop': crop_name,
                'temperature': temperature,
                'land_area': land_area
            },
            'recommendation': {
                'decision': 'RECOMMENDED' if success_prob[1] > 0.5 else 'NOT RECOMMENDED',
                'success_probability': success_prob[1] * 100,
                'confidence_level': 'High' if max(success_prob) > 0.8 else 'Medium' if max(success_prob) > 0.6 else 'Low'
            },
            'yield_profitability': {
                'yield_per_hectare': int(predicted_yield),
                'estimated_cost': int(cost),
                'predicted_profit': int(profit),
                'roi': roi
            },
            'risk_assessment': risk_level,
            'alternatives': alternatives,
            'seasonal_analysis': seasonal_analysis
        }
    
    def _prepare_input_features(self, district, soil_type, season, crop_name, temperature, rainfall, humidity, sunlight):
        """Prepare input features for prediction"""
        # Encode categorical features
        district_encoded = self.encoders['District'].transform([district])[0]
        soil_encoded = self.encoders['Soil_Type'].transform([soil_type])[0]
        season_encoded = self.encoders['Season'].transform([season])[0]
        crop_encoded = self.encoders['Crop_Name'].transform([crop_name])[0]
        
        # Create feature interactions
        temp_rainfall_interaction = temperature * rainfall
        humidity_sunlight_ratio = humidity / (sunlight + 1)
        
        # Create input array
        input_features = [
            district_encoded, soil_encoded, season_encoded, crop_encoded,
            temperature, rainfall, humidity, sunlight,
            temp_rainfall_interaction, humidity_sunlight_ratio
        ]
        
        # Scale features
        input_scaled = self.scaler.transform([input_features])[0]
        
        return input_scaled
    
    def _assess_risk(self, success_probability, predicted_yield, profit, temperature_penalty=0):
        """Assess risk level based on multiple factors"""
        risk_factors = []
        
        if temperature_penalty > 0.5:
            risk_factors.append("Extreme temperature conditions unsuitable for district")
        elif temperature_penalty > 0.2:
            risk_factors.append("Temperature outside normal district range")
            
        if success_probability < 0.4:
            risk_factors.append("Low success probability")
        if predicted_yield < 5000:  # Low yield
            risk_factors.append("Below average yield expected")
        if profit < 0:
            risk_factors.append("Negative profit projection")
        
        if len(risk_factors) >= 2:
            return "High risk conditions:\n   • " + "\n   • ".join(risk_factors)
        elif len(risk_factors) == 1:
            return "Medium risk conditions:\n   • " + risk_factors[0]
        else:
            return "Low risk conditions"
    
    def _get_alternative_crops(self, district, soil_type, season, temperature, rainfall, humidity, sunlight, top_n=5):
        """Get alternative crop recommendations"""
        alternatives = []
        
        available_crops = self.encoders['Crop_Name'].classes_
        
        for crop in available_crops:
            try:
                input_data = self._prepare_input_features(district, soil_type, season, crop, temperature, rainfall, humidity, sunlight)
                
                success_prob = self.models['success_classifier'].predict_proba([input_data])[0][1]
                predicted_yield = self.models['yield_predictor'].predict([input_data])[0]
                predicted_price = self.models['price_predictor'].predict([input_data])[0]
                
                cost = self.crop_costs.get(crop, 150000)
                profit = (predicted_yield * predicted_price) - cost
                
                alternatives.append({
                    'crop_name': crop,
                    'success_probability': success_prob * 100,
                    'yield_kg_per_ha': int(predicted_yield),
                    'profit_lkr_per_ha': int(profit)
                })
            except:
                continue
        
        # Sort by success probability and return top N
        alternatives.sort(key=lambda x: x['success_probability'], reverse=True)
        return alternatives[:top_n]
    
    def _generate_seasonal_analysis(self, district, soil_type, crop_name, temperature, rainfall, humidity, sunlight):
        """Generate seasonal analysis for upcoming seasons"""
        seasons = ['Maha', 'Yala']
        seasonal_data = []
        
        for season in seasons:
            try:
                input_data = self._prepare_input_features(district, soil_type, season, crop_name, temperature, rainfall, humidity, sunlight)
                
                success_prob = self.models['success_classifier'].predict_proba([input_data])[0][1]
                predicted_yield = self.models['yield_predictor'].predict([input_data])[0]
                predicted_price = self.models['price_predictor'].predict([input_data])[0]
                
                cost = self.crop_costs.get(crop_name, 150000)
                profit = (predicted_yield * predicted_price) - cost
                
                seasonal_data.append({
                    'season': f"{season} 2025/2026" if season == 'Maha' else f"{season} 2026",
                    'success_percentage': success_prob * 100,
                    'yield_kg_per_ha': int(predicted_yield),
                    'profit_lkr_per_ha': int(profit),
                    'recommended': success_prob > 0.5
                })
            except:
                continue
        
        return seasonal_data

# Global instance
ai_service = GreenPredictAIService()
