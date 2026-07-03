/// Represents a symptom selected by the patient.
class Symptom {
  final String id;
  final String name;

  const Symptom({required this.id, required this.name});

  Symptom copyWith({String? id, String? name}) {
    return Symptom(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Symptom && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Symptom(id: $id, name: $name)';
}

/// Common symptoms for search suggestions.
class SymptomSuggestions {
  static const List<Symptom> all = [
    Symptom(id: 'fever', name: 'Fever'),
    Symptom(id: 'cough', name: 'Cough'),
    Symptom(id: 'headache', name: 'Headache'),
    Symptom(id: 'fatigue', name: 'Fatigue'),
    Symptom(id: 'sore_throat', name: 'Sore Throat'),
    Symptom(id: 'shortness_breath', name: 'Shortness of Breath'),
    Symptom(id: 'body_aches', name: 'Body Aches'),
    Symptom(id: 'nausea', name: 'Nausea'),
    Symptom(id: 'dizziness', name: 'Dizziness'),
    Symptom(id: 'chest_pain', name: 'Chest Pain'),
    Symptom(id: 'runny_nose', name: 'Runny Nose'),
    Symptom(id: 'chills', name: 'Chills'),
  ];
}
