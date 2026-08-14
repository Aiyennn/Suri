/// API base URL and endpoint path constants.
abstract final class ApiConstants {
  /// Base URL for the Suri FastAPI backend.
  ///
  /// Use:
  ///   'http://localhost:8000'    → Windows / macOS / Linux desktop
  ///   'http://10.0.2.2:8000'    → Android emulator
  ///   'http://<your-LAN-IP>:8000' → Physical device on the same network
  static const String baseUrl = 'http://localhost:8000';

  // ── Auth endpoints ────────────────────────────────────────────────────
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  // ── Wound endpoints ───────────────────────────────────────────────────
  static const String woundAnalyze = '/wound/analyze';
  static const String woundAssessments = '/wound/assessments';

  // ── Medical facilities endpoints ─────────────────────────────────────
  static const String nearbyFacilities = '/medical-facilities/nearby';

  // ── Chatbot endpoints ────────────────────────────────────────────────
  static const String chatMessage = '/chatbot/message';
}
