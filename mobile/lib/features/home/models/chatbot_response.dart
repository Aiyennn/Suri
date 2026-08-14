/// Response model for POST /chatbot/message.
class ChatbotResponse {
  /// Classified intent. One of:
  ///   wound_assessment | skin_assessment | symptom_assessment |
  ///   needs_clarification | general_conversation
  final String intent;

  /// Natural-language reply to display in the chat UI.
  final String reply;

  /// Session identifier — pass back in the next request to preserve context.
  final String sessionId;

  const ChatbotResponse({
    required this.intent,
    required this.reply,
    required this.sessionId,
  });

  factory ChatbotResponse.fromJson(Map<String, dynamic> json) {
    return ChatbotResponse(
      intent: json['intent'] as String? ?? 'general_conversation',
      reply: json['reply'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? '',
    );
  }
}
