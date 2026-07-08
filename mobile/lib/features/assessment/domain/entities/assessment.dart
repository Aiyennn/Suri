/// Represents a rule triggered by the deterministic engine.
class TriggeredRule {
  final String id;
  final String name;
  final String reason;
  final int scoreContribution;

  const TriggeredRule({
    required this.id,
    required this.name,
    required this.reason,
    required this.scoreContribution,
  });

  factory TriggeredRule.fromJson(Map<String, dynamic> json) {
    return TriggeredRule(
      id: json['id'] as String,
      name: json['name'] as String,
      reason: json['reason'] as String,
      scoreContribution: json['score_contribution'] as int,
    );
  }
}

/// Represents the result of an AI health assessment from the deterministic rule engine.
class Assessment {
  final int riskScore;
  final String riskLevel;
  final List<String> recommendations;
  final bool referralRequired;
  final bool emergency;
  final String followUp;
  final List<TriggeredRule> triggeredRules;
  final String disclaimer;

  const Assessment({
    required this.riskScore,
    required this.riskLevel,
    required this.recommendations,
    required this.referralRequired,
    required this.emergency,
    required this.followUp,
    required this.triggeredRules,
    required this.disclaimer,
  });

  factory Assessment.fromJson(Map<String, dynamic> json) {
    final resultsList = json['results'] as List<dynamic>? ?? [];
    if (resultsList.isEmpty) {
      throw Exception('Assessment response contains no results');
    }
    
    final result = resultsList.first as Map<String, dynamic>;

    return Assessment(
      riskScore: result['risk_score'] as int,
      riskLevel: result['risk_level'] as String,
      recommendations: (result['recommendations'] as List<dynamic>?)?.cast<String>() ?? [],
      referralRequired: result['referral_required'] as bool? ?? false,
      emergency: result['emergency'] as bool? ?? false,
      followUp: result['follow_up'] as String? ?? '',
      triggeredRules: (result['triggered_rules'] as List<dynamic>?)
              ?.map((r) => TriggeredRule.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      disclaimer: result['disclaimer'] as String? ?? '',
    );
  }
}
