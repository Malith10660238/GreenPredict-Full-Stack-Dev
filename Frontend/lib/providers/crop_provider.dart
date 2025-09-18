import 'package:flutter/material.dart';
import '../models/ai_prediction_result.dart';
import '../services/api_service.dart';

class CropProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  AIPredictionResult? _lastPrediction;
  bool _isLoading = false;
  String? _errorMessage;
  
  AIPredictionResult? get lastPrediction => _lastPrediction;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  Future<void> getPrediction(Map<String, dynamic> inputData) async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Call the real backend API for AI predictions
      final predictionData = await _apiService.getPrediction(inputData);
      
      // Convert the response to AIPredictionResult
      _lastPrediction = AIPredictionResult.fromJson(predictionData);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('Failed to get prediction. Please try again.');
    }
  }
  
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}