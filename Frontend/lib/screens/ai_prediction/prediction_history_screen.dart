import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'ai_analysis_report_screen.dart';

class PredictionHistoryScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  
  const PredictionHistoryScreen({super.key, this.onNavigateToTab});

  @override
  State<PredictionHistoryScreen> createState() => _PredictionHistoryScreenState();
}

class _PredictionHistoryScreenState extends State<PredictionHistoryScreen> {
  List<Map<String, dynamic>> predictions = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadPredictionHistory();
  }

  Future<void> _loadPredictionHistory() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final apiService = ApiService();
      
      // Get the authentication token
      final token = authProvider.authToken;
      print('🔵 Prediction History Screen: Auth token available: ${token != null}');
      if (token == null) {
        throw Exception('User not authenticated');
      }
      
      final history = await apiService.getPredictionHistory(token);
      
      print('🔵 Prediction History Screen: Received ${history.length} predictions');
      print('🔵 Prediction History Screen: First prediction data: ${history.isNotEmpty ? history[0] : 'No predictions'}');
      
      setState(() {
        predictions = history;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: const Text(
          'Prediction History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryGreen,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryGreen,
              AppTheme.lightGreen,
              AppTheme.lightGray,
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Back Button
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Prediction History',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track your crop predictions over time',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Clear History Button (if there are predictions)
                    if (predictions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${predictions.length} Prediction${predictions.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showClearHistoryDialog,
                              icon: const Icon(Icons.clear_all, size: 18),
                              label: const Text('Clear All'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Stats Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.analytics_outlined,
                              color: AppTheme.primaryGreen,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AI Predictions',
                                  style: TextStyle(
                                    color: AppTheme.textDark,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'View and manage your crop prediction history',
                                  style: TextStyle(
                                    color: AppTheme.darkGray,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content Section
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryGreen,
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.primaryGreen.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading predictions',
              style: AppTheme.heading3.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.darkGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPredictionHistory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (predictions.isEmpty) {
      return _buildEmptyState();
    }

    return _buildPredictionList();
  }

  Widget _buildPredictionList() {
    print('🔵 Building prediction list with ${predictions.length} predictions');
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: RefreshIndicator(
        onRefresh: _loadPredictionHistory,
        color: AppTheme.primaryGreen,
        child: ListView.builder(
          itemCount: predictions.length,
          itemBuilder: (context, index) {
            final prediction = predictions[index];
            print('🔵 Building item $index: $prediction');
            return _buildPredictionCard(prediction);
          },
        ),
      ),
    );
  }

  Widget _buildPredictionCard(Map<String, dynamic> prediction) {
    print('🔵 Building prediction card for: $prediction');
    
    // Handle createdAt field - it might be a String or DateTime
    DateTime? createdAt;
    final createdAtValue = prediction['createdAt'];
    print('🔵 Raw createdAt value: $createdAtValue (type: ${createdAtValue.runtimeType})');
    
    if (createdAtValue is DateTime) {
      createdAt = createdAtValue;
      print('🔵 Parsed as DateTime: $createdAt');
    } else if (createdAtValue is String) {
      try {
        createdAt = DateTime.parse(createdAtValue);
        print('🔵 Parsed string to DateTime: $createdAt');
      } catch (e) {
        print('⚠️ Failed to parse createdAt: $createdAtValue, error: $e');
        createdAt = null;
      }
    } else {
      print('⚠️ Unknown createdAt type: ${createdAtValue.runtimeType}');
      createdAt = null;
    }
    
    // Debug: Show the final formatted date
    if (createdAt != null) {
      final formatted = _formatDate(createdAt);
      final now = DateTime.now();
      final nowUtc = now.toUtc();
      final dateUtc = createdAt.toUtc();
      final difference = nowUtc.difference(dateUtc);
      print('🔵 Formatted date: $formatted');
      print('🔵 Time difference (UTC): ${difference.inSeconds} seconds, ${difference.inMinutes} minutes, ${difference.inHours} hours, ${difference.inDays} days');
      print('🔵 Current time (local): $now');
      print('🔵 Current time (UTC): $nowUtc');
      print('🔵 Created time (local): $createdAt');
      print('🔵 Created time (UTC): $dateUtc');
    }
    
    print('🔵 Available fields in prediction: ${prediction.keys.toList()}');
    print('🔵 Raw cropType value: ${prediction['cropType']}');
    print('🔵 Raw location value: ${prediction['location']}');
    print('🔵 Raw predictedYield value: ${prediction['predictedYield']}');
    print('🔵 Raw confidence value: ${prediction['confidence']}');
    
    final cropType = prediction['cropType'] ?? 'Unknown Crop';
    final location = prediction['location'] ?? 'Unknown Location';
    final predictedYield = prediction['predictedYield'] ?? 'N/A';
    final confidence = (prediction['confidence'] ?? 0.0).toDouble();
    
    print('🔵 Card data - Crop: $cropType, Location: $location, Yield: $predictedYield, Confidence: $confidence');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getConfidenceColor(confidence).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _getConfidenceColor(confidence).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToPredictionDetail(prediction),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(confidence).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.agriculture,
                        color: _getConfidenceColor(confidence),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cropType,
                            style: AppTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppTheme.darkGray,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.darkGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getConfidenceColor(confidence).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getConfidenceColor(confidence).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${(confidence * 100).toInt()}%',
                            style: AppTheme.bodyMedium.copyWith(
                              color: _getConfidenceColor(confidence),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showDeleteDialog(prediction),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Details Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGray.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 18,
                              color: AppTheme.primaryGreen,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Yield: $predictedYield',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.textDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (createdAt != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatDate(createdAt),
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return AppTheme.primaryGreen;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    // Handle timezone differences - convert both to UTC for comparison
    final nowUtc = now.toUtc();
    final dateUtc = date.toUtc();
    final difference = nowUtc.difference(dateUtc);
    
    // More than 1 year ago
    if (difference.inDays >= 365) {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
    // More than 1 month ago
    else if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }
    // More than 1 week ago
    else if (difference.inDays >= 7) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    }
    // More than 1 day ago
    else if (difference.inDays > 0) {
      return difference.inDays == 1 ? '1 day ago' : '${difference.inDays} days ago';
    }
    // More than 1 hour ago
    else if (difference.inHours > 0) {
      return difference.inHours == 1 ? '1 hour ago' : '${difference.inHours} hours ago';
    }
    // More than 1 minute ago
    else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1 ? '1 minute ago' : '${difference.inMinutes} minutes ago';
    }
    // Less than 1 minute ago
    else if (difference.inSeconds > 30) {
      return '${difference.inSeconds} seconds ago';
    }
    // Very recent (less than 30 seconds)
    else {
      return 'Just now';
    }
  }

  void _navigateToPredictionDetail(Map<String, dynamic> prediction) {
    print('🔵 Navigation: Tapped on prediction: ${prediction['cropType']}');
    print('🔵 Navigation: Prediction data: $prediction');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIAnalysisReportScreen(
          predictionData: prediction,
        ),
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All History'),
          content: Text('Are you sure you want to delete all ${predictions.length} predictions? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearAllHistory();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(Map<String, dynamic> prediction) {
    final cropType = prediction['cropType'] ?? 'Unknown Crop';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Prediction'),
          content: Text('Are you sure you want to delete the prediction for $cropType? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deletePrediction(prediction);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllHistory() async {
    try {
      setState(() {
        isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final apiService = ApiService();
      final result = await apiService.deleteAllPredictions(token);
      
      setState(() {
        predictions.clear();
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'All predictions cleared successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing history: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePrediction(Map<String, dynamic> prediction) async {
    try {
      setState(() {
        isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final predictionId = prediction['prediction_id'];
      if (predictionId == null) {
        throw Exception('Prediction ID not found');
      }

      final apiService = ApiService();
      final result = await apiService.deletePrediction(predictionId, token);
      
      setState(() {
        predictions.remove(prediction);
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Prediction deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting prediction: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Empty State Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppTheme.primaryGreen.withOpacity(0.6),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Empty State Title
          Text(
            'No Predictions Yet',
            style: AppTheme.heading2.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Empty State Description
          Text(
            'Your AI crop predictions will appear here once you start using the prediction feature.',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.darkGray,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Action Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to AI prediction tab (index 1 for farmers)
              if (widget.onNavigateToTab != null) {
                widget.onNavigateToTab!(1);
              }
            },
            icon: const Icon(Icons.psychology),
            label: const Text('Start Predicting'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.lightGray.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Predictions help you make informed decisions about crop selection and farming practices.',
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.darkGray,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
