import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_constants.dart';
import '../models/chatbot_response.dart';

/// Handles communication with the backend chatbot API.
class ChatbotRepository {
  /// Send a user message and receive an intent-classified response.
  ///
  /// [message]   — The user's text.
  /// [sessionId] — Pass the session_id from the previous response to maintain
  ///               conversation history. Omit for the first message.
  /// [token]     — JWT access token for authentication.
  ///
  /// Throws a [ChatbotException] on network or server errors.
  Future<ChatbotResponse> sendMessage({
    required String message,
    String? sessionId,
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.chatMessage}');

    final body = <String, dynamic>{'message': message};
    if (sessionId != null) body['session_id'] = sessionId;

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ChatbotResponse.fromJson(json);
    }

    // Surface error messages from the backend when possible
    String detail = 'Chatbot error ${response.statusCode}';
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      detail = json['detail'] as String? ?? detail;
    } catch (_) {}

    throw ChatbotException(detail);
  }
}

/// Thrown when the chatbot API request fails.
class ChatbotException implements Exception {
  final String message;
  const ChatbotException(this.message);

  @override
  String toString() => 'ChatbotException: $message';
}
