class AIPredictionResult {
  final InputParameters inputParameters;
  final CurrentSeasonRecommendation currentSeasonRecommendation;
  final List<SeasonRecommendation> bestUpcomingSeasons;
  final YieldProfitabilityAnalysis yieldProfitabilityAnalysis;
  final RiskAssessment riskAssessment;
  final List<AlternativeCrop> alternativeCrops;

  AIPredictionResult({
    required this.inputParameters,
    required this.currentSeasonRecommendation,
    required this.bestUpcomingSeasons,
    required this.yieldProfitabilityAnalysis,
    required this.riskAssessment,
    required this.alternativeCrops,
  });

  factory AIPredictionResult.fromJson(Map<String, dynamic> json) {
    print('🔵 AIPredictionResult.fromJson: Parsing data...');
    print('🔵 Keys in json: ${json.keys.toList()}');
    
    // Safely handle the lists with proper null checking
    List<SeasonRecommendation> bestUpcomingSeasons = [];
    if (json['best_upcoming_seasons'] != null) {
      print('🔵 Found best_upcoming_seasons field');
      final seasonsList = json['best_upcoming_seasons'] as List<dynamic>?;
      print('🔵 Seasons list type: ${seasonsList.runtimeType}');
      if (seasonsList != null) {
        bestUpcomingSeasons = seasonsList
            .map((e) => SeasonRecommendation.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } else if (json['bestUpcomingSeasons'] != null) {
      print('🔵 Found bestUpcomingSeasons field');
      final seasonsList = json['bestUpcomingSeasons'] as List<dynamic>?;
      print('🔵 Seasons list type: ${seasonsList.runtimeType}');
      if (seasonsList != null) {
        bestUpcomingSeasons = seasonsList
            .map((e) => SeasonRecommendation.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    List<AlternativeCrop> alternativeCrops = [];
    if (json['alternative_crops'] != null) {
      print('🔵 Found alternative_crops field');
      final cropsList = json['alternative_crops'] as List<dynamic>?;
      print('🔵 Crops list type: ${cropsList.runtimeType}');
      if (cropsList != null) {
        alternativeCrops = cropsList
            .map((e) => AlternativeCrop.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } else if (json['alternativeCrops'] != null) {
      print('🔵 Found alternativeCrops field');
      final cropsList = json['alternativeCrops'] as List<dynamic>?;
      print('🔵 Crops list type: ${cropsList.runtimeType}');
      if (cropsList != null) {
        alternativeCrops = cropsList
            .map((e) => AlternativeCrop.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    print('🔵 Creating AIPredictionResult with ${bestUpcomingSeasons.length} seasons and ${alternativeCrops.length} alternative crops');
    
    return AIPredictionResult(
      inputParameters: InputParameters.fromJson(json['input_parameters'] ?? json['inputParameters']),
      currentSeasonRecommendation: CurrentSeasonRecommendation.fromJson(json['current_season_recommendation'] ?? json['currentSeasonRecommendation']),
      bestUpcomingSeasons: bestUpcomingSeasons,
      yieldProfitabilityAnalysis: YieldProfitabilityAnalysis.fromJson(json['yield_profitability_analysis'] ?? json['yieldProfitabilityAnalysis']),
      riskAssessment: RiskAssessment.fromJson(json['risk_assessment'] ?? json['riskAssessment']),
      alternativeCrops: alternativeCrops,
    );
  }
}

class InputParameters {
  final String planningYear;
  final String location;
  final String season;
  final String temperature;
  final String soilType;
  final String landArea;
  final String crop;

  InputParameters({
    required this.planningYear,
    required this.location,
    required this.season,
    required this.temperature,
    required this.soilType,
    required this.landArea,
    required this.crop,
  });

  factory InputParameters.fromJson(Map<String, dynamic> json) {
    return InputParameters(
      planningYear: json['planning_year']?.toString() ?? json['planningYear']?.toString() ?? '2025',
      location: json['location']?.toString() ?? 'Colombo',
      season: json['season']?.toString() ?? 'Yala',
      temperature: json['temperature']?.toString() ?? '28.0',
      soilType: json['soil_type']?.toString() ?? json['soilType']?.toString() ?? 'Latosols',
      landArea: json['land_area']?.toString() ?? json['landArea']?.toString() ?? '1.0',
      crop: json['crop']?.toString() ?? 'Cabbage',
    );
  }
}

class CurrentSeasonRecommendation {
  final String recommendedCrop;
  final int suitabilityScore;
  final List<String> reasons;
  final List<String> plantingTips;

  CurrentSeasonRecommendation({
    required this.recommendedCrop,
    required this.suitabilityScore,
    required this.reasons,
    required this.plantingTips,
  });

  factory CurrentSeasonRecommendation.fromJson(Map<String, dynamic> json) {
    return CurrentSeasonRecommendation(
      recommendedCrop: json['recommended_crop']?.toString() ?? json['recommendedCrop']?.toString() ?? 'Unknown',
      suitabilityScore: (json['suitability_score'] ?? json['suitabilityScore'] ?? 0) as int,
      reasons: List<String>.from(json['reasons'] ?? []),
      plantingTips: List<String>.from(json['planting_tips'] ?? json['plantingTips'] ?? []),
    );
  }
}

class SeasonRecommendation {
  final String season;
  final int suitabilityScore;
  final String expectedYield;
  final String profitabilityRating;

  SeasonRecommendation({
    required this.season,
    required this.suitabilityScore,
    required this.expectedYield,
    required this.profitabilityRating,
  });

  factory SeasonRecommendation.fromJson(Map<String, dynamic> json) {
    print('🔵 SeasonRecommendation.fromJson: Parsing season data');
    print('🔵 Season keys: ${json.keys.toList()}');
    
    try {
      return SeasonRecommendation(
        season: json['season']?.toString() ?? 'Unknown',
        suitabilityScore: (json['suitability_score'] ?? json['suitabilityScore'] ?? 0) as int,
        expectedYield: json['expected_yield']?.toString() ?? json['expectedYield']?.toString() ?? 'N/A',
        profitabilityRating: json['profitability_rating']?.toString() ?? json['profitabilityRating']?.toString() ?? 'Unknown',
      );
    } catch (e) {
      print('❌ SeasonRecommendation.fromJson error: $e');
      print('❌ Season data: $json');
      rethrow;
    }
  }
}

class YieldProfitabilityAnalysis {
  final String expectedYield;
  final String estimatedRevenue;
  final String estimatedCosts;
  final String netProfit;
  final String profitMargin;
  final String breakEvenTime;

  YieldProfitabilityAnalysis({
    required this.expectedYield,
    required this.estimatedRevenue,
    required this.estimatedCosts,
    required this.netProfit,
    required this.profitMargin,
    required this.breakEvenTime,
  });

  factory YieldProfitabilityAnalysis.fromJson(Map<String, dynamic> json) {
    return YieldProfitabilityAnalysis(
      expectedYield: json['expected_yield']?.toString() ?? json['expectedYield']?.toString() ?? 'N/A',
      estimatedRevenue: json['estimated_revenue']?.toString() ?? json['estimatedRevenue']?.toString() ?? 'N/A',
      estimatedCosts: json['estimated_costs']?.toString() ?? json['estimatedCosts']?.toString() ?? 'N/A',
      netProfit: json['net_profit']?.toString() ?? json['netProfit']?.toString() ?? 'N/A',
      profitMargin: json['profit_margin']?.toString() ?? json['profitMargin']?.toString() ?? 'N/A',
      breakEvenTime: json['break_even_time']?.toString() ?? json['breakEvenTime']?.toString() ?? 'N/A',
    );
  }
}

class RiskAssessment {
  final String overallRisk;
  final String weatherRisk;
  final String marketRisk;
  final String pestDiseaseRisk;
  final List<String> recommendations;

  RiskAssessment({
    required this.overallRisk,
    required this.weatherRisk,
    required this.marketRisk,
    required this.pestDiseaseRisk,
    required this.recommendations,
  });

  factory RiskAssessment.fromJson(Map<String, dynamic> json) {
    return RiskAssessment(
      overallRisk: json['overall_risk']?.toString() ?? json['overallRisk']?.toString() ?? 'Unknown',
      weatherRisk: json['weather_risk']?.toString() ?? json['weatherRisk']?.toString() ?? 'Unknown',
      marketRisk: json['market_risk']?.toString() ?? json['marketRisk']?.toString() ?? 'Unknown',
      pestDiseaseRisk: json['pest_disease_risk']?.toString() ?? json['pestDiseaseRisk']?.toString() ?? 'Unknown',
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }
}

class AlternativeCrop {
  final String name;
  final int suitabilityScore;
  final String expectedProfit;
  final String growthPeriod;

  AlternativeCrop({
    required this.name,
    required this.suitabilityScore,
    required this.expectedProfit,
    required this.growthPeriod,
  });

  factory AlternativeCrop.fromJson(Map<String, dynamic> json) {
    print('🔵 AlternativeCrop.fromJson: Parsing crop data');
    print('🔵 Crop keys: ${json.keys.toList()}');
    
    try {
      return AlternativeCrop(
        name: json['name']?.toString() ?? 'Unknown',
        suitabilityScore: (json['suitability_score'] ?? json['suitabilityScore'] ?? 0) as int,
        expectedProfit: json['expected_profit']?.toString() ?? json['expectedProfit']?.toString() ?? 'N/A',
        growthPeriod: json['growth_period']?.toString() ?? json['growthPeriod']?.toString() ?? 'N/A',
      );
    } catch (e) {
      print('❌ AlternativeCrop.fromJson error: $e');
      print('❌ Crop data: $json');
      rethrow;
    }
  }
}