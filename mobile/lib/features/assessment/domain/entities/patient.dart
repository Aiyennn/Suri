/// Represents a patient's data collected during assessment intake.
class Patient {
  final int? age;
  final String? sex;
  final List<String> symptoms;
  final String? duration;
  final String? medicalHistory;

  const Patient({
    this.age,
    this.sex,
    this.symptoms = const [],
    this.duration,
    this.medicalHistory,
  });

  Patient copyWith({
    int? age,
    String? sex,
    List<String>? symptoms,
    String? duration,
    String? medicalHistory,
  }) {
    return Patient(
      age: age ?? this.age,
      sex: sex ?? this.sex,
      symptoms: symptoms ?? this.symptoms,
      duration: duration ?? this.duration,
      medicalHistory: medicalHistory ?? this.medicalHistory,
    );
  }

  bool get isValid =>
      age != null &&
      age! > 0 &&
      sex != null &&
      symptoms.isNotEmpty &&
      duration != null;
}
