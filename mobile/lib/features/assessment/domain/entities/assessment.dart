import 'condition.dart';

/// Represents the result of an AI health assessment.
class Assessment {
  final String urgencyTitle;
  final String urgencyDescription;
  final int score;
  final double confidence;
  final String timeframe;
  final String recommendationTitle;
  final String recommendationDescription;
  final List<Condition> conditions;
  final List<String> reasoningPoints;
  final List<SelfCareItem> selfCareItems;

  const Assessment({
    required this.urgencyTitle,
    required this.urgencyDescription,
    required this.score,
    required this.confidence,
    required this.timeframe,
    required this.recommendationTitle,
    required this.recommendationDescription,
    required this.conditions,
    required this.reasoningPoints,
    required this.selfCareItems,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    return Assessment(
      urgencyTitle: json['urgency_title'] as String,
      urgencyDescription: json['urgency_description'] as String,
      score: json['score'] as int,
      confidence: (json['confidence'] as num).toDouble(),
      timeframe: json['timeframe'] as String,
      recommendationTitle: json['recommendation_title'] as String,
      recommendationDescription: json['recommendation_description'] as String,
      conditions: (json['conditions'] as List<dynamic>)
          .map((c) => Condition.fromJson(c as Map<String, dynamic>))
          .toList(),
      reasoningPoints:
          (json['reasoning_points'] as List<dynamic>).cast<String>(),
      selfCareItems: (json['self_care_items'] as List<dynamic>)
          .map((s) => SelfCareItem.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Self-care recommendation item.
class SelfCareItem {
  final String label;
  final String iconName;

  const SelfCareItem({required this.label, required this.iconName});

  factory SelfCareItem.fromJson(Map<String, dynamic> json) {
    return SelfCareItem(
      label: json['label'] as String,
      iconName: json['icon_name'] as String,
    );
  }
}

