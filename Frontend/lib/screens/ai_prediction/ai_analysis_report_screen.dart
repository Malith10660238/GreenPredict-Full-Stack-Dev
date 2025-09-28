import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/crop_provider.dart';
import '../../utils/app_theme.dart';

class AIAnalysisReportScreen extends StatelessWidget {
  final Map<String, dynamic>? predictionData;
  
  const AIAnalysisReportScreen({super.key, this.predictionData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.lightGradient,
        ),
        child: Consumer<CropProvider>(
        builder: (context, cropProvider, child) {
          // Use predictionData if available, otherwise fall back to provider data
          final prediction = predictionData ?? cropProvider.lastPrediction;
          
          print('🔵 AIAnalysisReportScreen: Prediction data: $prediction');
          print('🔵 AIAnalysisReportScreen: Is loading: ${cropProvider.isLoading}');
          print('🔵 AIAnalysisReportScreen: Error: ${cropProvider.errorMessage}');
          print('🔵 AIAnalysisReportScreen: Using predictionData: ${predictionData != null}');
          print('🔵 AIAnalysisReportScreen: Using provider data: ${predictionData == null && cropProvider.lastPrediction != null}');
          if (prediction != null && prediction is Map<String, dynamic>) {
            print('🔵 AIAnalysisReportScreen: Final prediction keys: ${prediction.keys.toList()}');
            print('🔵 AIAnalysisReportScreen: cropType: ${prediction['cropType']}');
            print('🔵 AIAnalysisReportScreen: location: ${prediction['location']}');
            print('🔵 AIAnalysisReportScreen: confidence: ${prediction['confidence']}');
          }
          
          // Handle loading state only for new predictions (when predictionData is null)
          if (cropProvider.isLoading && predictionData == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryGreen),
                  SizedBox(height: 16),
                  Text(
                    'Analyzing with AI...',
                    style: TextStyle(
                      color: AppTheme.textDark, 
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }
          
          // Handle error state only for new predictions (when predictionData is null)
          if (cropProvider.errorMessage != null && predictionData == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 64),
                    const SizedBox(height: 24),
                    Text(
                      'Analysis Error',
                      style: AppTheme.heading2.copyWith(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      cropProvider.errorMessage!,
                      style: AppTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: AppTheme.primaryButtonStyle,
                          child: const Text('Go Back'),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: () {
                            cropProvider.clearError();
                            Navigator.pop(context);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Handle case when no prediction data is available
          if (prediction == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.analytics_outlined, color: AppTheme.primaryGreen, size: 64),
                    const SizedBox(height: 24),
                    Text(
                      'No Analysis Data',
                      style: AppTheme.heading2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please go back and try the AI analysis again',
                      style: AppTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: AppTheme.primaryButtonStyle,
                          child: const Text('Go Back'),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: () {
                            final cropProvider = Provider.of<CropProvider>(context, listen: false);
                            cropProvider.clearError();
                            Navigator.pop(context);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
          
          return CustomScrollView(
            slivers: [
              // Header with title
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.primaryGreen,
                centerTitle: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'AI Analysis Report',
                    style: AppTheme.heading3.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  centerTitle: true,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'AI-Powered Crop Analysis',
                            style: AppTheme.bodyLarge.copyWith(
                              color: AppTheme.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              
              // Content
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Current Season Recommendation (with success rate circle)
                    () {
                      print('🔵 Building Current Season Recommendation...');
                      final currentSeasonData = _getCurrentSeasonRecommendation(prediction);
                      print('🔵 Current Season Data: $currentSeasonData');
                      return _buildCurrentSeasonRecommendation(currentSeasonData, prediction);
                    }(),
                    
                    const SizedBox(height: 20),
                    
                    // Input Parameters Section
                    () {
                      print('🔵 Building Input Parameters Section...');
                      final inputParamsData = _getInputParameters(prediction);
                      print('🔵 Input Parameters Data: $inputParamsData');
                      return _buildInputParametersSection(inputParamsData, prediction);
                    }(),
                    
                    const SizedBox(height: 20),
                    
                    // Yield & Profitability Analysis
                    () {
                      print('🔵 Building Yield Analysis Section...');
                      final yieldData = _getYieldAnalysis(prediction);
                      print('🔵 Yield Data: $yieldData');
                      return _buildYieldProfitabilitySection(yieldData);
                    }(),
                    
                    const SizedBox(height: 20),
                    
                    // Best Upcoming Seasons
                    _buildUpcomingSeasonsSection(_getUpcomingSeasons(prediction), _getCropName(prediction), prediction),
                    
                    const SizedBox(height: 20),
                    
                    // Risk Assessment
                    _buildRiskAssessmentSection(_getRiskAssessment(prediction)),
                    
                    const SizedBox(height: 20),
                    
                    // Alternative Crops
                    _buildAlternativeCropsSection(_getAlternativeCrops(prediction)),
                    
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    ),
    );
  }

  Widget _buildInputParametersSection(inputParams, fullPrediction) {
    print('🔵 _buildInputParametersSection: inputParams = $inputParams');
    print('🔵 _buildInputParametersSection: fullPrediction = $fullPrediction');
    
    if (inputParams == null) {
      print('🔵 _buildInputParametersSection: inputParams is null, returning SizedBox.shrink()');
      return const SizedBox.shrink();
    }
    
    // Helper function to get value from either Map or Object
    String getValue(String key) {
      if (inputParams is Map<String, dynamic>) {
        // Map the camelCase keys to snake_case keys that are actually in the data
        String actualKey = key;
        switch (key) {
          case 'planningYear':
            actualKey = 'planning_year';
            break;
          case 'landArea':
            actualKey = 'land_area';
            break;
          case 'soilType':
            actualKey = 'soil_type';
            break;
          case 'temperature':
            actualKey = 'temperature';
            break;
          case 'crop':
            // For crop, get it from the root level of the full prediction
            if (fullPrediction is Map<String, dynamic>) {
              final cropValue = fullPrediction['cropType']?.toString() ?? 'N/A';
              print('🔵 _buildInputParametersSection: getValue($key) from fullPrediction = $cropValue');
              return cropValue;
            }
            return 'N/A';
          case 'location':
            // For location, get it from the root level of the full prediction
            if (fullPrediction is Map<String, dynamic>) {
              final locationValue = fullPrediction['location']?.toString() ?? 'N/A';
              print('🔵 _buildInputParametersSection: getValue($key) from fullPrediction = $locationValue');
              return locationValue;
            }
            return 'N/A';
          default:
            actualKey = key;
        }
        
        final value = inputParams[actualKey]?.toString() ?? 'N/A';
        
        // Provide default values for soil type and temperature when not provided
        if (value == 'N/A' || value == 'null' || value.isEmpty) {
          switch (key) {
            case 'soilType':
              // Get district-specific soil type default
              final location = fullPrediction is Map<String, dynamic> 
                  ? fullPrediction['location']?.toString() ?? 'Colombo'
                  : 'Colombo';
              final soilType = _getDistrictSoilType(location);
              print('🔵 _buildInputParametersSection: getValue($key -> $actualKey) = Default soil type for $location: $soilType');
              return soilType;
            case 'temperature':
              // Get district-specific temperature default
              final location = fullPrediction is Map<String, dynamic> 
                  ? fullPrediction['location']?.toString() ?? 'Colombo'
                  : 'Colombo';
              final temperature = _getDistrictTemperature(location);
              print('🔵 _buildInputParametersSection: getValue($key -> $actualKey) = Default temperature for $location: $temperature');
              return temperature;
            default:
              print('🔵 _buildInputParametersSection: getValue($key -> $actualKey) = $value');
              return value;
          }
        }
        
        print('🔵 _buildInputParametersSection: getValue($key -> $actualKey) = $value');
        return value;
      } else {
        // Handle object properties
        try {
          switch (key) {
            case 'planningYear':
              return inputParams.planningYear?.toString() ?? 'N/A';
            case 'location':
              return inputParams.location?.toString() ?? 'N/A';
            case 'soilType':
              return inputParams.soilType?.toString() ?? 'N/A';
            case 'season':
              return inputParams.season?.toString() ?? 'N/A';
            case 'crop':
              return inputParams.crop?.toString() ?? 'N/A';
            case 'temperature':
              return inputParams.temperature?.toString() ?? 'N/A';
            case 'landArea':
              return inputParams.landArea?.toString() ?? 'N/A';
            default:
              return 'N/A';
          }
        } catch (e) {
          // Provide default values for soil type and temperature when not provided
          switch (key) {
            case 'soilType':
              // Get district-specific soil type default
              final location = fullPrediction is Map<String, dynamic> 
                  ? fullPrediction['location']?.toString() ?? 'Colombo'
                  : 'Colombo';
              return _getDistrictSoilType(location);
            case 'temperature':
              // Get district-specific temperature default
              final location = fullPrediction is Map<String, dynamic> 
                  ? fullPrediction['location']?.toString() ?? 'Colombo'
                  : 'Colombo';
              return _getDistrictTemperature(location);
            default:
              return 'N/A';
          }
        }
      }
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.input, color: AppTheme.primaryGreen, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Input Parameters',
                  style: AppTheme.heading3,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildParameterRow('Planning Year', getValue('planningYear')),
            _buildParameterRow('District', getValue('location')),
            _buildParameterRow('Soil Type', getValue('soilType')),
            _buildParameterRow('Current Season', getValue('season')),
            _buildParameterRow('Crop', getValue('crop')),
            _buildParameterRow('Temperature', getValue('temperature') == 'N/A' ? 'N/A' : '${getValue('temperature')}°C'),
            _buildParameterRow('Land Area', '${getValue('landArea')} hectares'),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.darkGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSeasonRecommendation(recommendation, dynamic prediction) {
    print('🔵 _buildCurrentSeasonRecommendation: recommendation = $recommendation');
    
    if (recommendation == null) {
      print('🔵 _buildCurrentSeasonRecommendation: recommendation is null, returning SizedBox.shrink()');
      return const SizedBox.shrink();
    }
    
    // Handle both object and map formats
    final suitabilityScore = recommendation is Map<String, dynamic> 
        ? _safeToDouble(recommendation['suitability_score'] ?? recommendation['suitabilityScore'])
        : _safeToDouble(recommendation.suitabilityScore);
    
    print('🔵 _buildCurrentSeasonRecommendation: suitabilityScore = $suitabilityScore');
    
    final isRecommended = suitabilityScore >= 50;
    final decisionColor = isRecommended ? AppTheme.accentGreen : Colors.red;
    final decisionText = isRecommended ? 'RECOMMENDED' : 'NOT RECOMMENDED';
    
    print('🔵 _buildCurrentSeasonRecommendation: isRecommended = $isRecommended, decisionText = $decisionText');
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.lightGreen, AppTheme.mintGreen],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: decisionColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isRecommended ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Season',
                        style: AppTheme.heading3.copyWith(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'AI Recommendation',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.darkGray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // AI Decision
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: decisionColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: decisionColor.withOpacity(0.3)),
              ),
              child: Text(
                decisionText,
                style: TextStyle(
                  color: decisionColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Highlighted Success Rate Circle - MAIN FOCUS
            _buildSuccessRateCircle(_extractSuccessRate(recommendation)),
            
            const SizedBox(height: 20),
            
            // Key Insights Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: AppTheme.primaryGreen, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Key Insights',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInsightItem('Expected Yield', _getRecommendationReason(recommendation)),
                  _buildInsightItem('Confidence Level', _getConfidenceLevel(prediction)),
                  _buildInsightItem('Risk Assessment', _getRiskAssessmentLevel(prediction)),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Additional info chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildInfoChip('Confidence Level', _getConfidenceLevel(prediction), Icons.verified),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip('Range', '${suitabilityScore.round()}%', Icons.trending_up),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Planting Tips Section
            if (_getPlantingTips(recommendation).isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tips_and_updates, color: AppTheme.primaryGreen, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Planting Tips',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._getPlantingTips(recommendation).take(3).map((tip) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(top: 6, right: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                tip,
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.darkGray,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessRateCircle(int successRate) {
    // Determine color based on success rate
    Color circleColor;
    if (successRate >= 70) {
      circleColor = Colors.green; // High - Green
    } else if (successRate >= 40) {
      circleColor = Colors.orange; // Medium - Yellow/Orange
    } else {
      circleColor = Colors.red; // Low - Red
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Text(
            'Success Probability',
            style: AppTheme.heading2.copyWith(
              color: AppTheme.darkGray,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleColor,
                boxShadow: [
                  BoxShadow(
                    color: circleColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$successRate%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SUCCESS',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: circleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: circleColor.withOpacity(0.3), width: 2),
              ),
              child: Text(
                _getSuccessRateLabel(successRate),
                style: TextStyle(
                  color: circleColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label: $value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.darkGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  String _getSuccessRateLabel(int successRate) {
    if (successRate >= 70) {
      return 'Excellent';
    } else if (successRate >= 50) {
      return 'Good';
    } else if (successRate >= 30) {
      return 'Fair';
    } else {
      return 'Poor';
    }
  }


  Widget _buildUpcomingSeasonsSection(List<dynamic> seasons, String cropName, dynamic prediction) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppTheme.lightGreen.withOpacity(0.1),
            ],
          ),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: AppTheme.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Seasons for $cropName',
                        style: AppTheme.heading3.copyWith(
                          color: AppTheme.textDark,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AI-powered seasonal recommendations',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.darkGray,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...seasons.map((season) => _buildSeasonCard(season, prediction)),
          ],
        ),
      ),
    );
  }


  Widget _buildSeasonCard(season, dynamic prediction) {
    if (season == null) return const SizedBox.shrink();
    
    // Get planning year from prediction data
    int planningYear = _getPlanningYear(prediction);
    
    // Helper function to get value from either Map or Object
    String getSeasonValue(String key) {
      if (season is Map<String, dynamic>) {
        return season[key]?.toString() ?? 'N/A';
      } else {
        try {
          switch (key) {
            case 'season':
              return season.season?.toString() ?? 'N/A';
            case 'expectedYield':
              return season.expectedYield?.toString() ?? 'N/A';
            case 'profitabilityRating':
              return season.profitabilityRating?.toString() ?? 'N/A';
            default:
              return 'N/A';
          }
        } catch (e) {
          return 'N/A';
        }
      }
    }
    
    // Helper function to get dynamic year based on season index
    String getDynamicYear() {
      final fullSeasonName = getSeasonValue('season');
      print('🔵 getDynamicYear: fullSeasonName = $fullSeasonName, planningYear = $planningYear');
      
      // Extract just the season name (before any year or space)
      String seasonName = fullSeasonName;
      if (fullSeasonName.contains(' ')) {
        seasonName = fullSeasonName.split(' ')[0];
      }
      print('🔵 getDynamicYear: extracted seasonName = $seasonName');
      
      // Define seasons in order (Yala, Maha)
      final seasons = ['Yala', 'Maha'];
      final seasonIndex = seasons.indexOf(seasonName);
      print('🔵 getDynamicYear: seasonIndex = $seasonIndex');
      
      if (seasonIndex >= 0) {
        // Calculate year based on planning year + 1 (next year only, same for all seasons)
        final dynamicYear = planningYear + 1;
        print('🔵 getDynamicYear: calculated year = $dynamicYear');
        return dynamicYear.toString();
      }
      final fallbackYear = planningYear + 1;
      print('🔵 getDynamicYear: fallback year = $fallbackYear');
      return fallbackYear.toString();
    }
    
    // Handle both object and map formats
    final suitabilityScore = season is Map<String, dynamic> 
        ? _safeToDouble(season['suitabilityScore'])
        : _safeToDouble(season.suitabilityScore);
    
    final isRecommended = suitabilityScore >= 50;
    final statusColor = isRecommended ? AppTheme.primaryGreen : Colors.orange;
    final statusText = isRecommended ? 'Recommended' : 'Not Recommended';
    final statusIcon = isRecommended ? Icons.check_circle : Icons.cancel;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with season name and status
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${getSeasonValue('season').split(' ')[0]} ${getDynamicYear()}',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.textDark,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        statusText,
                        style: AppTheme.bodyMedium.copyWith(
                          color: statusColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Details section
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Success percentage with progress indicator
                _buildDetailRow(
                  icon: Icons.analytics_outlined,
                  label: 'Success Rate',
                  value: '${suitabilityScore.round()}%',
                  color: statusColor,
                  showProgress: true,
                  progress: suitabilityScore / 100,
                ),
                const SizedBox(height: 20),
                
                // Yield information
                _buildDetailRow(
                  icon: Icons.agriculture_outlined,
                  label: 'Expected Yield',
                  value: getSeasonValue('expectedYield'),
                  color: AppTheme.darkGray,
                ),
                const SizedBox(height: 20),
                
                // Profitability
                _buildDetailRow(
                  icon: Icons.trending_up_outlined,
                  label: 'Profitability',
                  value: getSeasonValue('profitabilityRating'),
                  color: AppTheme.primaryGreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool showProgress = false,
    double? progress,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.darkGray,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (showProgress && progress != null)
                    Container(
                      width: 80,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYieldProfitabilitySection(analysis) {
    if (analysis == null) {
      return const SizedBox.shrink();
    }
    
    // Helper function to get value from either Map or Object
    String getAnalysisValue(String key) {
      if (analysis is Map<String, dynamic>) {
        // Map camelCase keys to snake_case keys that are actually in the data
        String actualKey = key;
        switch (key) {
          case 'expectedYield':
            actualKey = 'expected_yield';
            break;
          case 'estimatedCosts':
            actualKey = 'estimated_costs';
            break;
          case 'netProfit':
            actualKey = 'net_profit';
            break;
          case 'profitMargin':
            actualKey = 'profit_margin';
            break;
          default:
            actualKey = key;
        }
        return analysis[actualKey]?.toString() ?? 'N/A';
      } else {
        try {
          switch (key) {
            case 'expectedYield':
              return analysis.expectedYield?.toString() ?? 'N/A';
            case 'estimatedCosts':
              return analysis.estimatedCosts?.toString() ?? 'N/A';
            case 'netProfit':
              return analysis.netProfit?.toString() ?? 'N/A';
            case 'profitMargin':
              return analysis.profitMargin?.toString() ?? 'N/A';
            default:
              return 'N/A';
          }
        } catch (e) {
          return 'N/A';
        }
      }
    }
    
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.lightGreen, AppTheme.mintGreen],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: AppTheme.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Yield & Profitability Analysis',
                    style: AppTheme.heading3.copyWith(
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildModernAnalysisRow('Yield per Hectare', getAnalysisValue('expectedYield'), Icons.grass, AppTheme.primaryGreen),
            _buildModernAnalysisRow('Estimated Cost', getAnalysisValue('estimatedCosts'), Icons.money_off, Colors.orange),
            _buildModernAnalysisRow('Predicted Profit', getAnalysisValue('netProfit'), Icons.trending_up, AppTheme.accentGreen),
            _buildModernAnalysisRow('Return on Investment', getAnalysisValue('profitMargin'), Icons.percent, AppTheme.primaryGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAnalysisRow(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: AppTheme.heading3.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAssessmentSection(riskAssessment) {
    if (riskAssessment == null) {
      return const SizedBox.shrink();
    }
    
    // Helper function to get value from either Map or Object
    String getRiskValue(String key) {
      if (riskAssessment is Map<String, dynamic>) {
        return riskAssessment[key]?.toString() ?? 'N/A';
      } else {
        try {
          switch (key) {
            case 'overallRisk':
              return riskAssessment.overallRisk?.toString() ?? 'N/A';
            default:
              return 'N/A';
          }
        } catch (e) {
          return 'N/A';
        }
      }
    }
    
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.lightGreen, AppTheme.mintGreen],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.security,
                    color: AppTheme.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Risk Assessment',
                    style: AppTheme.heading3.copyWith(
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
              ),
              child: Text(
                getRiskValue('overallRisk'),
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlternativeCropsSection(List<dynamic> alternatives) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.lightGreen, AppTheme.mintGreen],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: AppTheme.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Top 5 Alternative Crop Recommendations',
                    style: AppTheme.heading3.copyWith(
                      color: AppTheme.textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...alternatives.take(5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final crop = entry.value;
              return _buildModernAlternativeCropCard(index + 1, crop);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAlternativeCropCard(int rank, crop) {
    if (crop == null) return const SizedBox.shrink();
    
    // Handle both object and map formats
    final suitabilityScore = crop is Map<String, dynamic> 
        ? _safeToDouble(crop['suitabilityScore'])
        : _safeToDouble(crop.suitabilityScore);
    
    final cropName = crop is Map<String, dynamic> 
        ? (crop['name'] ?? 'Unknown Crop')
        : (crop.name ?? 'Unknown Crop');
    
    final cardColor = AppTheme.primaryGreen;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Crop info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cropName,
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.textDark,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        color: cardColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Success Rate: ',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.darkGray,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${suitabilityScore.round()}%',
                        style: AppTheme.bodyMedium.copyWith(
                          color: cardColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to safely convert values to double
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Helper method to get district-specific soil type default
  String _getDistrictSoilType(String district) {
    final districtSoilDefaults = {
      'Ampara': 'Reddish Brown Earths',
      'Anuradhapura': 'Alluvial Soils',
      'Badulla': 'Red-Yellow Podzolic Soils',
      'Batticaloa': 'Regosols',
      'Colombo': 'Latosols',
      'Galle': 'Latosols',
      'Gampaha': 'Latosols',
      'Hambantota': 'Reddish Brown Earths',
      'Jaffna': 'Regosols',
      'Kalutara': 'Red-Yellow Podzolic Soils',
      'Kandy': 'Reddish Brown Earths',
      'Kegalle': 'Latosols',
      'Kilinochchi': 'Reddish Brown Earths',
      'Kurunegala': 'Alluvial Soils',
      'Mannar': 'Regosols',
      'Matale': 'Reddish Brown Earths',
      'Matara': 'Alluvial Soils',
      'Monaragala': 'Reddish Brown Earths',
      'Mullaitivu': 'Latosols',
      'Nuwara Eliya': 'Red-Yellow Podzolic Soils',
      'Polonnaruwa': 'Alluvial Soils',
      'Puttalam': 'Calcic Red Latosols',
      'Ratnapura': 'Red-Yellow Podzolic Soils',
      'Trincomalee': 'Alluvial Soils',
      'Vavuniya': 'Reddish Brown Earths'
    };
    return districtSoilDefaults[district] ?? 'Latosols';
  }

  // Helper method to get district-specific temperature default
  String _getDistrictTemperature(String district) {
    final districtTempDefaults = {
      'Ampara': '30.0',
      'Anuradhapura': '30.0',
      'Badulla': '21.5',
      'Batticaloa': '29.4',
      'Colombo': '28.4',
      'Galle': '28.4',
      'Gampaha': '28.5',
      'Hambantota': '30.1',
      'Jaffna': '30.8',
      'Kalutara': '28.5',
      'Kandy': '23.9',
      'Kegalle': '27.5',
      'Kilinochchi': '30.1',
      'Kurunegala': '29.6',
      'Mannar': '30.1',
      'Matale': '25.9',
      'Matara': '28.6',
      'Monaragala': '29.1',
      'Mullaitivu': '29.5',
      'Nuwara Eliya': '15.0',
      'Polonnaruwa': '30.0',
      'Puttalam': '29.5',
      'Ratnapura': '26.5',
      'Trincomalee': '30.6',
      'Vavuniya': '29.6'
    };
    return districtTempDefaults[district] ?? '27.5';
  }

  // Helper method to extract success rate from reasons
  int _extractSuccessRate(dynamic recommendation) {
    if (recommendation == null) return 0;
    
    // Handle both object and map formats
    if (recommendation is Map<String, dynamic>) {
      final reasons = recommendation['reasons'];
      if (reasons != null && reasons is List && reasons.isNotEmpty) {
        // Look for success probability in the reasons
        for (final reason in reasons) {
          final reasonStr = reason.toString();
          if (reasonStr.contains('Success probability:')) {
            // Extract the percentage from "Success probability: 97.6%"
            final match = RegExp(r'(\d+\.?\d*)%').firstMatch(reasonStr);
            if (match != null) {
              final percentage = double.tryParse(match.group(1) ?? '0') ?? 0.0;
              return percentage.floor();
            }
          }
        }
      }
    } else {
      // Handle object format
      try {
        if (recommendation.reasons != null && recommendation.reasons.isNotEmpty) {
          for (final reason in recommendation.reasons) {
            final reasonStr = reason.toString();
            if (reasonStr.contains('Success probability:')) {
              // Extract the percentage from "Success probability: 97.6%"
              final match = RegExp(r'(\d+\.?\d*)%').firstMatch(reasonStr);
              if (match != null) {
                final percentage = double.tryParse(match.group(1) ?? '0') ?? 0.0;
                return percentage.floor();
              }
            }
          }
        }
      } catch (e) {
        // Fallback if reasons property doesn't exist
      }
    }
    
    // Fallback to 0 if no success probability found
    return 0;
  }

  // Helper method to safely get recommendation reason (yield data)
  String _getRecommendationReason(dynamic recommendation) {
    if (recommendation == null) return 'Calculating...';
    
    // Handle both object and map formats
    if (recommendation is Map<String, dynamic>) {
      // For historical data, try to get yield from reasons array
      final reasons = recommendation['reasons'];
      if (reasons != null && reasons is List && reasons.isNotEmpty) {
        // Look for yield information in the reasons
        for (final reason in reasons) {
          if (reason.toString().contains('Expected yield:')) {
            return reason.toString();
          }
        }
        // If no yield found, return the first reason
        return reasons.first.toString();
      }
      return 'Calculating...';
    }
    
    // Handle object format
    try {
      if (recommendation.reasons != null && recommendation.reasons.isNotEmpty) {
        // Look for yield information in the reasons
        for (final reason in recommendation.reasons) {
          if (reason.toString().contains('Expected yield:')) {
            return reason.toString();
          }
        }
        // If no yield found, return the first reason
        return recommendation.reasons.first;
      }
    } catch (e) {
      // Fallback if reasons property doesn't exist
    }
    
    return 'Calculating...';
  }

  // Helper method to safely get planting tips
  List<String> _getPlantingTips(dynamic recommendation) {
    if (recommendation == null) return [];
    
    // Handle both object and map formats
    if (recommendation is Map<String, dynamic>) {
      // For historical data, try to get from risk assessment recommendations
      final riskAssessment = recommendation['risk_assessment'];
      if (riskAssessment != null && riskAssessment['recommendations'] != null) {
        final recommendations = riskAssessment['recommendations'];
        if (recommendations is List) {
          return recommendations.map((r) => r.toString()).toList();
        }
      }
      return [];
    }
    
    // Handle object format
    try {
      if (recommendation.plantingTips != null && recommendation.plantingTips.isNotEmpty) {
        return List<String>.from(recommendation.plantingTips);
      }
    } catch (e) {
      // Fallback if plantingTips property doesn't exist
    }
    
    return [];
  }

  // Helper methods to extract data from both prediction formats
  dynamic _getCurrentSeasonRecommendation(dynamic prediction) {
    if (prediction == null) return null;
    
    print('🔵 _getCurrentSeasonRecommendation: prediction = $prediction');
    
    // Check if it's from prediction history (Map format)
    if (prediction is Map<String, dynamic>) {
      final aiAnalysis = prediction['ai_analysis'];
      print('🔵 _getCurrentSeasonRecommendation: aiAnalysis = $aiAnalysis');
      
      if (aiAnalysis != null) {
        // Try to get current_season first
        if (aiAnalysis['current_season'] != null) {
          print('🔵 _getCurrentSeasonRecommendation: Found current_season in ai_analysis');
          final result = aiAnalysis['current_season'];
          print('🔵 _getCurrentSeasonRecommendation: Returning current_season = $result');
          return result;
        }
        
        // Fallback: create a mock current season from available data
        final cropType = prediction['cropType'] ?? 'Unknown Crop';
        final confidence = _safeToDouble(prediction['confidence']);
        
        // Try to get suitability score from current_season data
        int suitabilityScore = (confidence * 100).round();
        if (aiAnalysis['current_season'] != null) {
          final currentSeason = aiAnalysis['current_season'];
          final score = currentSeason['suitability_score'];
          if (score != null) {
            suitabilityScore = _safeToDouble(score).round();
          }
        }
        
        // Try to extract success probability from reasons if available
        if (aiAnalysis['current_season'] != null && aiAnalysis['current_season']['reasons'] != null) {
          final reasons = aiAnalysis['current_season']['reasons'] as List;
          for (final reason in reasons) {
            final reasonStr = reason.toString();
            if (reasonStr.contains('Success probability:')) {
              final match = RegExp(r'(\d+\.?\d*)%').firstMatch(reasonStr);
              if (match != null) {
                suitabilityScore = double.tryParse(match.group(1) ?? '0')?.round() ?? suitabilityScore;
                break;
              }
            }
          }
        }
        
        final result = {
          'suitabilityScore': suitabilityScore,
          'reasons': aiAnalysis['current_season']?['reasons'] ?? ['Based on historical prediction data'],
          'season': 'Current Season',
          'cropType': cropType,
        };
        print('🔵 _getCurrentSeasonRecommendation: Created fallback result with suitabilityScore = $suitabilityScore');
        return result;
      }
    }
    
    // Check if it's from provider (object format)
    try {
      return prediction.currentSeasonRecommendation;
    } catch (e) {
      return null;
    }
  }

  dynamic _getInputParameters(dynamic prediction) {
    if (prediction == null) return null;
    
    print('🔵 _getInputParameters: prediction = $prediction');
    
    // Check if it's from prediction history (Map format)
    if (prediction is Map<String, dynamic>) {
      final aiAnalysis = prediction['ai_analysis'];
      print('🔵 _getInputParameters: aiAnalysis = $aiAnalysis');
      
      if (aiAnalysis != null && aiAnalysis['input_parameters'] != null) {
        print('🔵 _getInputParameters: Found input_parameters in ai_analysis');
        final result = aiAnalysis['input_parameters'];
        print('🔵 _getInputParameters: Returning input_parameters = $result');
        return result;
      }
      
      // If not found, construct from root level data and input_parameters
      final inputParams = prediction['input_parameters'] ?? {};
      final result = {
        'planning_year': inputParams['planning_year'] ?? DateTime.now().year.toString(),
        'location': prediction['location'] ?? inputParams['location'] ?? 'Unknown',
        'soil_type': inputParams['soil_type'] ?? 'Unknown',
        'season': inputParams['season'] ?? 'Unknown',
        'crop': prediction['cropType'] ?? inputParams['crop'] ?? 'Unknown',
        'temperature': inputParams['temperature']?.toString() ?? 'Unknown',
        'land_area': inputParams['land_area']?.toString() ?? '1.0',
      };
      print('🔵 _getInputParameters: Created result from root data = $result');
      return result;
    }
    
    // Check if it's from provider (object format)
    try {
      return prediction.inputParameters;
    } catch (e) {
      return null;
    }
  }

  dynamic _getYieldAnalysis(dynamic prediction) {
    if (prediction == null) return null;
    
    print('🔵 _getYieldAnalysis: prediction = $prediction');
    
    // Check if it's from prediction history (Map format)
    if (prediction is Map<String, dynamic>) {
      final aiAnalysis = prediction['ai_analysis'];
      print('🔵 _getYieldAnalysis: aiAnalysis = $aiAnalysis');
      
      if (aiAnalysis != null && aiAnalysis['yield_analysis'] != null) {
        print('🔵 _getYieldAnalysis: Found yield_analysis in ai_analysis');
        final result = aiAnalysis['yield_analysis'];
        print('🔵 _getYieldAnalysis: Returning yield_analysis = $result');
        return result;
      }
      
      // If not found, construct from available data
      final predictedYield = prediction['predictedYield'] ?? 'Unknown';
      final confidence = prediction['confidence'] ?? 0.0;
      
      // Try to get more detailed yield data from ai_analysis
      final yieldAnalysis = aiAnalysis['yield_analysis'] ?? {};
      
      final result = {
        'expected_yield': yieldAnalysis['expected_yield'] ?? predictedYield,
        'estimated_costs': yieldAnalysis['estimated_costs'] ?? 'LKR 250,000',
        'estimated_revenue': yieldAnalysis['estimated_revenue'] ?? 'LKR 235,329',
        'net_profit': yieldAnalysis['net_profit'] ?? 'LKR -14,671',
        'profit_margin': yieldAnalysis['profit_margin'] ?? '${(confidence * 100).toStringAsFixed(1)}%',
      };
      print('🔵 _getYieldAnalysis: Created result from available data = $result');
      return result;
    }
    
    // Check if it's from provider (object format)
    try {
      return prediction.yieldProfitabilityAnalysis;
    } catch (e) {
      return null;
    }
  }

  List<dynamic> _getUpcomingSeasons(dynamic prediction) {
    if (prediction == null) return [];
    
    // Check if it's from prediction history (Map format)
    if (prediction is Map<String, dynamic>) {
      final aiAnalysis = prediction['ai_analysis'];
      if (aiAnalysis != null && aiAnalysis['upcoming_seasons'] != null) {
        return List<dynamic>.from(aiAnalysis['upcoming_seasons']);
      }
    }
    
    // Check if it's from provider (object format)
    try {
      return List<dynamic>.from(prediction.bestUpcomingSeasons ?? []);
    } catch (e) {
      return [];
    }
  }

  String _getCropName(dynamic prediction) {
    if (prediction == null) return 'Unknown';
    
    // Check if it's from prediction history (Map format)
    if (prediction is Map<String, dynamic>) {
      return prediction['cropType'] ?? 'Unknown';
    }
    
    // Check if it's from provider (object format)
    try {
      return prediction.inputParameters?.crop ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  dynamic _getRiskAssessment(dynamic prediction) {
    if (prediction == null) return null;
    
    // Check if it's from prediction history (Map format)
    if (prediction is Map<String, dynamic>) {
      final aiAnalysis = prediction['ai_analysis'];
      if (aiAnalysis != null && aiAnalysis['risk_assessment'] != null) {
        return aiAnalysis['risk_assessment'];
      }
    }
    
    // Check if it's from provider (object format)
    try {
      return prediction.riskAssessment;
    } catch (e) {
      return null;
    }
  }

  List<dynamic> _getAlternativeCrops(dynamic prediction) {
    if (prediction == null) return [];
    
    // Check if it's from prediction history (Map format)
    if (prediction is Map<String, dynamic>) {
      final aiAnalysis = prediction['ai_analysis'];
      if (aiAnalysis != null && aiAnalysis['alternative_crops'] != null) {
        return List<dynamic>.from(aiAnalysis['alternative_crops']);
      }
    }
    
    // Check if it's from provider (object format)
    try {
      return List<dynamic>.from(prediction.alternativeCrops ?? []);
    } catch (e) {
      return [];
    }
  }

  // Helper method to extract confidence level from prediction data
  String _getConfidenceLevel(dynamic prediction) {
    if (prediction == null) return 'Unknown';
    
    // Check if it's from prediction history (Map format)
    if (prediction is Map<String, dynamic>) {
      final confidence = prediction['confidence'];
      if (confidence != null) {
        final confidenceValue = double.tryParse(confidence.toString()) ?? 0.0;
        if (confidenceValue >= 0.8) return 'High';
        if (confidenceValue >= 0.6) return 'Medium';
        if (confidenceValue >= 0.4) return 'Low';
        return 'Very Low';
      }
      
      // Try to get from ai_analysis
      final aiAnalysis = prediction['ai_analysis'];
      if (aiAnalysis != null && aiAnalysis['current_season'] != null) {
        final currentSeason = aiAnalysis['current_season'];
        if (currentSeason['reasons'] != null && currentSeason['reasons'] is List) {
          final reasons = currentSeason['reasons'] as List;
          for (final reason in reasons) {
            final reasonStr = reason.toString();
            if (reasonStr.contains('Confidence level:')) {
              final match = RegExp(r'Confidence level:\s*(\w+)', caseSensitive: false).firstMatch(reasonStr);
              if (match != null) {
                return match.group(1) ?? 'Unknown';
              }
            }
          }
        }
      }
    }
    
    // Check if it's from provider (object format)
    try {
      final confidence = prediction.confidence;
      if (confidence != null) {
        final confidenceValue = double.tryParse(confidence.toString()) ?? 0.0;
        if (confidenceValue >= 0.8) return 'High';
        if (confidenceValue >= 0.6) return 'Medium';
        if (confidenceValue >= 0.4) return 'Low';
        return 'Very Low';
      }
    } catch (e) {
      // Fallback if confidence property doesn't exist
    }
    
    return 'Unknown';
  }

  // Helper method to extract risk assessment level from prediction data
  String _getRiskAssessmentLevel(dynamic prediction) {
    if (prediction == null) return 'Unknown';
    
    // Check if it's from prediction history (Map format)
    if (prediction is Map<String, dynamic>) {
      final aiAnalysis = prediction['ai_analysis'];
      if (aiAnalysis != null && aiAnalysis['risk_assessment'] != null) {
        final riskAssessment = aiAnalysis['risk_assessment'];
        final overallRisk = riskAssessment['overall_risk'];
        if (overallRisk != null) {
          return overallRisk.toString();
        }
      }
    }
    
    // Check if it's from provider (object format)
    try {
      final riskAssessment = prediction.riskAssessment;
      if (riskAssessment != null) {
        return riskAssessment.overallRisk?.toString() ?? 'Unknown';
      }
    } catch (e) {
      // Fallback if riskAssessment property doesn't exist
    }
    
    return 'Unknown';
  }

  // Helper method to extract planning year from prediction data
  int _getPlanningYear(dynamic prediction) {
    print('🔵 _getPlanningYear: prediction = $prediction');
    
    if (prediction == null) {
      print('🔵 _getPlanningYear: prediction is null, using current year');
      return DateTime.now().year;
    }
    
    // Check if it's from prediction history (Map format)
    if (prediction is Map<String, dynamic>) {
      print('🔵 _getPlanningYear: prediction is Map format');
      final aiAnalysis = prediction['ai_analysis'];
      if (aiAnalysis != null && aiAnalysis['input_parameters'] != null) {
        final inputParams = aiAnalysis['input_parameters'];
        final planningYear = inputParams['planning_year'];
        print('🔵 _getPlanningYear: found planning_year in input_parameters = $planningYear');
        if (planningYear != null) {
          final year = int.tryParse(planningYear.toString()) ?? DateTime.now().year;
          print('🔵 _getPlanningYear: parsed year = $year');
          return year;
        }
      }
      
      // Fallback to root level planning_year
      final planningYear = prediction['planning_year'];
      print('🔵 _getPlanningYear: root level planning_year = $planningYear');
      if (planningYear != null) {
        final year = int.tryParse(planningYear.toString()) ?? DateTime.now().year;
        print('🔵 _getPlanningYear: parsed root year = $year');
        return year;
      }
    }
    
    // Check if it's from provider (object format)
    try {
      final planningYear = prediction.inputParameters?.planningYear;
      print('🔵 _getPlanningYear: provider planningYear = $planningYear');
      if (planningYear != null) {
        final year = int.tryParse(planningYear.toString()) ?? DateTime.now().year;
        print('🔵 _getPlanningYear: parsed provider year = $year');
        return year;
      }
    } catch (e) {
      print('🔵 _getPlanningYear: error accessing inputParameters: $e');
    }
    
    // Default to current year if not found
    print('🔵 _getPlanningYear: using current year as fallback');
    return DateTime.now().year;
  }
}

