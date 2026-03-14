/// Handles all HTTP communication between the Jaspr frontend and the
/// Firebase Cloud Functions backend.
///
/// Other frontend code should call [ApiService] methods rather than
/// making HTTP requests directly.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/opportunity.dart';

/// The parsed response returned by [ApiService.sendMessage].
class ApiResponse {
  final String reply;
  final List<Opportunity> opportunities;

  ApiResponse({required this.reply, this.opportunities = const []});
}

/// Stateless service that sends chat messages to the backend and returns
/// structured responses.
class ApiService {
  /// Override at compile time: `--dart-define=API_BASE_URL=https://...`
  /// Defaults to the local Firebase emulator URL.
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5001/your-project-id/us-central1',
  );

  /// A simple per-tab session identifier.
  static final String _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

  /// Sends [message] to the `handleChatMessage` Cloud Function and returns
  /// the AI's reply together with any matched opportunities.
  static Future<ApiResponse> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/handleChatMessage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': _sessionId,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final opportunities =
            (data['opportunities'] as List<dynamic>?)
                ?.map((o) => Opportunity.fromJson(o as Map<String, dynamic>))
                .toList() ??
            <Opportunity>[];

        return ApiResponse(
          reply: (data['reply'] as String?) ?? 'Sorry, I could not process your request.',
          opportunities: opportunities,
        );
      } else {
        return ApiResponse(
          reply: 'Error: Server returned status ${response.statusCode}. Please try again.',
        );
      }
    } catch (e) {
      return ApiResponse(
        reply:
            'Unable to connect to the server. Make sure the Firebase backend '
            'is running.\n\n'
            'Tip: Run "cd functions && npm run serve" to start the local emulator.',
      );
    }
  }
}
