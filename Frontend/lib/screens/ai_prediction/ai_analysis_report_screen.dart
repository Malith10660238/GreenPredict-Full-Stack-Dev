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
          // Use provided prediction data or fall back to provider data
          final prediction = predictionData ?? cropProvider.lastPrediction;
          
          print('🔵 AIAnalysisReportScreen: Prediction data: $prediction');
          print('🔵 AIAnalysisReportScreen: Is loading: ${cropProvider.isLoading}');
          print('🔵 AIAnalysisReportScreen: Error: ${cropProvider.errorMessage}');
          
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
          
          if (prediction == null && predictionData == null) {
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
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Current Season Recommendation (with success rate circle)
                    _buildCurrentSeasonRecommendation(_getCurrentSeasonRecommendation(prediction)),
                    
                    const SizedBox(height: 20),
                    
                    // Input Parameters Section
                    _buildInputParametersSection(_getInputParameters(prediction)),
                    
                    const SizedBox(height: 20),
                    
                    // Yield & Profitability Analysis
                    _buildYieldProfitabilitySection(_getYieldAnalysis(prediction)),
                    
                    const SizedBox(height: 20),
                    
                    // Best Upcoming Seasons
                    _buildUpcomingSeasonsSection(_getUpcomingSeasons(prediction), _getCropName(prediction)),
                    
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

  Widget _buildInputParametersSection(inputParams) {
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
            _buildParameterRow('Planning Year', inputParams.planningYear),
            _buildParameterRow('District', inputParams.location),
            _buildParameterRow('Soil Type', inputParams.soilType),
            _buildParameterRow('Current Season', inputParams.season),
            _buildParameterRow('Crop', inputParams.crop),
            _buildParameterRow('Temperature', '${inputParams.temperature}°C'),
            _buildParameterRow('Land Area', '${inputParams.landArea} hectares'),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSeasonRecommendation(recommendation) {
    final isRecommended = recommendation.suitabilityScore >= 50;
    final decisionColor = isRecommended ? AppTheme.accentGreen : Colors.red;
    final decisionText = isRecommended ? 'RECOMMENDED' : 'NOT RECOMMENDED';
    
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
            _buildSuccessRateCircle(recommendation.suitabilityScore),
            
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
                  _buildInsightItem('Expected Yield', recommendation.reasons.isNotEmpty ? recommendation.reasons.first : 'Calculating...'),
                  _buildInsightItem('Confidence Level', 'High'),
                  _buildInsightItem('Risk Assessment', isRecommended ? 'Low Risk' : 'High Risk'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Additional info chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoChip('Confidence Level', 'High', Icons.verified),
                _buildInfoChip('Range', '${recommendation.suitabilityScore}%', Icons.trending_up),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Planting Tips Section
            if (recommendation.plantingTips.isNotEmpty) ...[
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
                    ...recommendation.plantingTips.take(3).map((tip) => 
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
          Text(
            '$label: $value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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


  Widget _buildUpcomingSeasonsSection(List<dynamic> seasons, String cropName) {
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
            ...seasons.map((season) => _buildSeasonCard(season)),
          ],
        ),
      ),
    );
  }


  Widget _buildSeasonCard(season) {
    final isRecommended = season.suitabilityScore >= 50;
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
                        season.season,
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
                  value: '${season.suitabilityScore}%',
                  color: statusColor,
                  showProgress: true,
                  progress: season.suitabilityScore / 100,
                ),
                const SizedBox(height: 20),
                
                // Yield information
                _buildDetailRow(
                  icon: Icons.agriculture_outlined,
                  label: 'Expected Yield',
                  value: season.expectedYield,
                  color: AppTheme.darkGray,
                ),
                const SizedBox(height: 20),
                
                // Profitability
                _buildDetailRow(
                  icon: Icons.trending_up_outlined,
                  label: 'Profitability',
                  value: season.profitabilityRating,
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
            _buildModernAnalysisRow('Yield per Hectare', analysis.expectedYield, Icons.grass, AppTheme.primaryGreen),
            _buildModernAnalysisRow('Estimated Cost', analysis.estimatedCosts, Icons.money_off, Colors.orange),
            _buildModernAnalysisRow('Predicted Profit', analysis.netProfit, Icons.trending_up, AppTheme.accentGreen),
            _buildModernAnalysisRow('Return on Investment', analysis.profitMargin, Icons.percent, AppTheme.primaryGreen),
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
                riskAssessment.overallRisk,
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
                    crop.name,
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
                        '${crop.suitabilityScore}%',
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

  // Helper methods to extract data from both prediction formats
  dynamic _getCurrentSeasonRecommendation(dynamic prediction) {
    if (prediction == null) return null;
    
    // Check if it's from prediction history (Map format)
    if (prediction is Map<String, dynamic>) {
      final aiAnalysis = prediction['ai_analysis'];
      if (aiAnalysis != null && aiAnalysis['current_season'] != null) {
        return aiAnalysis['current_season'];
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
    
    // Check if it's from prediction history (Map format)
    if (prediction is Map<String, dynamic>) {
      final aiAnalysis = prediction['ai_analysis'];
      if (aiAnalysis != null && aiAnalysis['input_parameters'] != null) {
        return aiAnalysis['input_parameters'];
      }
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
    
    // Check if it's from prediction history (Map format)
    if (prediction is Map<String, dynamic>) {
      final aiAnalysis = prediction['ai_analysis'];
      if (aiAnalysis != null && aiAnalysis['yield_analysis'] != null) {
        return aiAnalysis['yield_analysis'];
      }
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
}

