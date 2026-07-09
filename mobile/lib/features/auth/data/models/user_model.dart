/// Public user profile returned by the backend after login or register.
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? dateOfBirth;
  final String? sex;
  final String? medicalHistory;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.dateOfBirth,
    this.sex,
    this.medicalHistory,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      dateOfBirth: json['date_of_birth'] as String?,
      sex: json['sex'] as String?,
      medicalHistory: json['medical_history'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
