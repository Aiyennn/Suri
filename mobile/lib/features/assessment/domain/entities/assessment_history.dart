/// Lightweight summary of one past assessment, matching the backend
/// `AssessmentSummary` schema.
class AssessmentHistoryItem {
  final String id;
  final DateTime createdAt;
  final String patientAge;
  final String patientSex;
  final List<String> symptoms;
  final String duration;
  final String? riskLevel;
  final int? riskScore;
  final String? woundType;
  final bool? emergency;
  final int imageCount;

  const AssessmentHistoryItem({
    required this.id,
    required this.createdAt,
    required this.patientAge,
    required this.patientSex,
    required this.symptoms,
    required this.duration,
    this.riskLevel,
    this.riskScore,
    this.woundType,
    this.emergency,
    required this.imageCount,
  });

  factory AssessmentHistoryItem.fromJson(Map<String, dynamic> json) {
    return AssessmentHistoryItem(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      patientAge: json['patient_age'] as String,
      patientSex: json['patient_sex'] as String,
      symptoms: (json['symptoms'] as List<dynamic>).cast<String>(),
      duration: json['duration'] as String,
      riskLevel: json['risk_level'] as String?,
      riskScore: json['risk_score'] as int?,
      woundType: json['wound_type'] as String?,
      emergency: json['emergency'] as bool?,
      imageCount: json['image_count'] as int? ?? 0,
    );
  }
}

class AssessmentHistoryResponse {
  final int total;
  final List<AssessmentHistoryItem> assessments;

  const AssessmentHistoryResponse({
    required this.total,
    required this.assessments,
  });

  factory AssessmentHistoryResponse.fromJson(Map<String, dynamic> json) {
    return AssessmentHistoryResponse(
      total: json['total'] as int,
      assessments: (json['assessments'] as List<dynamic>)
          .map((e) => AssessmentHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
