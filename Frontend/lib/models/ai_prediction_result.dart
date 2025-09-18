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
    return AIPredictionResult(
      inputParameters: InputParameters.fromJson(json['inputParameters']),
      currentSeasonRecommendation: CurrentSeasonRecommendation.fromJson(json['currentSeasonRecommendation']),
      bestUpcomingSeasons: (json['bestUpcomingSeasons'] as List)
          .map((e) => SeasonRecommendation.fromJson(e))
          .toList(),
      yieldProfitabilityAnalysis: YieldProfitabilityAnalysis.fromJson(json['yieldProfitabilityAnalysis']),
      riskAssessment: RiskAssessment.fromJson(json['riskAssessment']),
      alternativeCrops: (json['alternativeCrops'] as List)
          .map((e) => AlternativeCrop.fromJson(e))
          .toList(),
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
      planningYear: json['planningYear'],
      location: json['location'],
      season: json['season'],
      temperature: json['temperature'],
      soilType: json['soilType'],
      landArea: json['landArea'],
      crop: json['crop'],
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
      recommendedCrop: json['recommendedCrop'],
      suitabilityScore: json['suitabilityScore'],
      reasons: List<String>.from(json['reasons']),
      plantingTips: List<String>.from(json['plantingTips']),
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
    return SeasonRecommendation(
      season: json['season'],
      suitabilityScore: json['suitabilityScore'],
      expectedYield: json['expectedYield'],
      profitabilityRating: json['profitabilityRating'],
    );
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
      expectedYield: json['expectedYield'],
      estimatedRevenue: json['estimatedRevenue'],
      estimatedCosts: json['estimatedCosts'],
      netProfit: json['netProfit'],
      profitMargin: json['profitMargin'],
      breakEvenTime: json['breakEvenTime'],
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
      overallRisk: json['overallRisk'],
      weatherRisk: json['weatherRisk'],
      marketRisk: json['marketRisk'],
      pestDiseaseRisk: json['pestDiseaseRisk'],
      recommendations: List<String>.from(json['recommendations']),
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
    return AlternativeCrop(
      name: json['name'],
      suitabilityScore: json['suitabilityScore'],
      expectedProfit: json['expectedProfit'],
      growthPeriod: json['growthPeriod'],
    );
  }
}