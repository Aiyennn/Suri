import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../models/auth_token.dart';
import '../models/user_model.dart';

/// Pairs together a [UserModel] and its [AuthToken].
class AuthResult {
  final AuthToken token;
  final UserModel user;

  const AuthResult({required this.token, required this.user});
}

/// Handles all authentication network calls and local token persistence.
///
/// Token storage uses [FlutterSecureStorage] which writes to:
///  - Android Keystore on Android
///  - iOS Keychain on iOS
///
/// Usage:
/// ```dart
/// final repo = AuthRepository();
/// final result = await repo.login(email: 'a@b.com', password: 'secret');
/// ```
class AuthRepository {
  static const _tokenKey = 'auth_token';

  final http.Client _client;
  final FlutterSecureStorage _storage;

  AuthRepository({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ??
            const FlutterSecureStorage(
              // Windows uses the Credential Manager (Windows Data Protection API).
              wOptions: WindowsOptions(),
            );

  // ── Public API ────────────────────────────────────────────────────────────

  /// Register a new account.
  ///
  /// Throws a [String] error message on failure.
  Future<AuthResult> register({
    required String email,
    required String password,
    required String fullName,
    String? sex,
    String? dateOfBirth,
    String? medicalHistory,
  }) async {
    final body = <String, String>{
      'email': email,
      'password': password,
      'full_name': fullName,
      if (sex case final s?) 'sex': s,
      if (dateOfBirth case final d?) 'date_of_birth': d,
      if (medicalHistory case final m?) 'medical_history': m,
    };

    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return _handleAuthResponse(response);
  }

  /// Log in with email and password.
  ///
  /// Throws a [String] error message on failure.
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    return _handleAuthResponse(response);
  }

  /// Persist the JWT token to secure storage.
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {
      // Storage unavailable — session won't persist across restarts.
    }
  }

  /// Read the stored JWT token, or `null` if none is saved.
  Future<String?> readToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  /// Delete the stored JWT token (logout).
  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {
      // Ignore — token is effectively gone from the app's perspective.
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  AuthResult _handleAuthResponse(http.Response response) {
    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      final token = AuthToken.fromJson(
        json['token'] as Map<String, dynamic>,
      );
      final user = UserModel.fromJson(
        json['user'] as Map<String, dynamic>,
      );
      return AuthResult(token: token, user: user);
    }

    // Surface the backend's error detail to the UI.
    final detail = json['detail'];
    if (detail is String) throw detail;
    throw 'An unexpected error occurred. Please try again.';
  }
}
