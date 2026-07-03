/// Represents a medical image uploaded by the patient.
class MedicalImage {
  final String id;
  final String category; // skin, throat, eye, wound
  final String filePath;
  final String? thumbnailPath;
  final int fileSizeBytes;

  const MedicalImage({
    required this.id,
    required this.category,
    required this.filePath,
    this.thumbnailPath,
    this.fileSizeBytes = 0,
  });

  MedicalImage copyWith({
    String? id,
    String? category,
    String? filePath,
    String? thumbnailPath,
    int? fileSizeBytes,
  }) {
    return MedicalImage(
      id: id ?? this.id,
      category: category ?? this.category,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MedicalImage && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Categories for medical image uploads.
enum ImageCategory {
  skin('Skin', '🩹'),
  throat('Throat', '👅'),
  eye('Eye', '👁'),
  wound('Wound', '🩸');

  const ImageCategory(this.label, this.emoji);
  final String label;
  final String emoji;
}
