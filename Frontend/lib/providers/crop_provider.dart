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
      
      print('🔵 CropProvider: Getting prediction with data: $inputData');
      
      // Call the real backend API for AI predictions
      final predictionData = await _apiService.getPrediction(inputData);
      
      print('🔵 CropProvider: Received response: $predictionData');
      
      // Convert the response to AIPredictionResult
      // The response structure is: { "result": { ... } }
      if (predictionData['result'] != null) {
        print('🔵 CropProvider: Using result field from response');
        try {
          _lastPrediction = AIPredictionResult.fromJson(predictionData['result']);
        } catch (e) {
          print('❌ CropProvider: Error parsing result field: $e');
          print('❌ Result data: ${predictionData['result']}');
          throw Exception('Failed to parse AI prediction result: $e');
        }
      } else {
        print('🔵 CropProvider: Using full response as result');
        try {
          _lastPrediction = AIPredictionResult.fromJson(predictionData);
        } catch (e) {
          print('❌ CropProvider: Error parsing full response: $e');
          print('❌ Full data: $predictionData');
          throw Exception('Failed to parse AI prediction result: $e');
        }
      }
      
      print('🔵 CropProvider: Prediction set successfully: ${_lastPrediction != null}');
      _setLoading(false);
    } catch (e) {
      print('❌ CropProvider: Error getting prediction: $e');
      _setLoading(false);
      _setError('Failed to get prediction. Please try again.');
    }
  }
  
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}