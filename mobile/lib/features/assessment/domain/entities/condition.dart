/// A possible medical condition identified by the AI.
class Condition {
  final String name;
  final String description;
  final double percentage;

  const Condition({
    required this.name,
    required this.description,
    required this.percentage,
  });

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      name: json['name'] as String,
      description: json['description'] as String,
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}
