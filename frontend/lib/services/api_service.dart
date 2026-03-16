library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import '../constants.dart';
import '../models/opportunity.dart';

class ApiResponse {
  final String reply;
  final List<Opportunity> opportunities;

  ApiResponse({required this.reply, this.opportunities = const []});
}

class ApiService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // In production we want to talk to the Render API, not localhost.
    defaultValue: 'https://ai-opportunity-advisor.onrender.com',
  );

  static String get _sessionId {
    final uid = web.window.localStorage.getItem('pathora_uid');
    if (uid != null && uid.isNotEmpty) return uid;

    const fallbackKey = 'pathora_fallback_session';
    final existing = web.window.localStorage.getItem(fallbackKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final generated = 'session_${DateTime.now().millisecondsSinceEpoch}';
    web.window.localStorage.setItem(fallbackKey, generated);
    return generated;
  }

  static Map<String, String> get _authHeaders {
    final token = web.window.localStorage.getItem('pathora_id_token');
    if (token == null || token.isEmpty) return {};
    return {'Authorization': 'Bearer $token'};
  }

  static bool get _isAuthenticated =>
      web.window.localStorage.getItem('pathora_id_token') != null &&
      web.window.localStorage.getItem('pathora_id_token')!.isNotEmpty;

  static Future<ApiResponse> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpointChat'),
        headers: {
          'Content-Type': 'application/json',
          ..._authHeaders,
        },
        body: jsonEncode({
          'sessionId': _sessionId,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final opportunities = (data['opportunities'] as List<dynamic>?)
                ?.map(
                    (o) => Opportunity.fromJson(o as Map<String, dynamic>))
                .toList() ??
            <Opportunity>[];

        return ApiResponse(
          reply: (data['reply'] as String?) ??
              'Sorry, I could not process your request.',
          opportunities: opportunities,
        );
      } else {
        return ApiResponse(
          reply:
              'Error: Server returned status ${response.statusCode}. Please try again.',
        );
      }
    } catch (e) {
      return ApiResponse(
        reply:
            'Unable to connect to the server. Make sure the backend is running on $_baseUrl.',
      );
    }
  }

  /// Load existing conversation history for the current session/user.
  ///
  /// Returns a list of `{role, content}` maps suitable for `ChatMessage`.
  static Future<List<Map<String, String>>> loadConversation() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$endpointConversation/$_sessionId'),
        headers: _authHeaders,
      );

      if (response.statusCode != 200) return const [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = data['messages'] as List<dynamic>? ?? const [];

      return raw
          .whereType<Map<String, dynamic>>()
          .map((m) => {
                'role': (m['role'] as String?) ?? roleAssistant,
                'content': (m['content'] as String?) ?? '',
              })
          .where((m) => m['content']!.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // ─── Multi-conversation API ───

  /// A lightweight conversation summary (for the sidebar list).
  static Future<List<Map<String, dynamic>>> listConversations() async {
    // Fallback: if not authenticated, behave like a single-session chat.
    if (!_isAuthenticated) {
      return [
        {
          'id': _sessionId,
          'title': 'Current chat',
        }
      ];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$endpointMyConversations'),
        headers: _authHeaders,
      );
      if (response.statusCode != 200) return const [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = data['conversations'] as List<dynamic>? ?? const [];
      return raw.cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }

  /// Create a new conversation. Returns `{ id, title }`.
  static Future<Map<String, dynamic>?> createConversation({
    String title = 'New chat',
  }) async {
    // Fallback: unauthenticated users just use the single session id.
    if (!_isAuthenticated) {
      return {
        'id': _sessionId,
        'title': title,
      };
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpointMyConversations'),
        headers: {'Content-Type': 'application/json', ..._authHeaders},
        body: jsonEncode({'title': title}),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Delete a conversation.
  static Future<bool> deleteConversation(String conversationId) async {
    // Fallback: nothing to delete for unauthenticated single-session chats.
    if (!_isAuthenticated) {
      return true;
    }

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$endpointMyConversations/$conversationId'),
        headers: _authHeaders,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Load all messages for a specific conversation.
  static Future<List<Map<String, String>>> loadConversationMessages(
    String conversationId,
  ) async {
    // Fallback: use legacy single-session endpoint when not authenticated.
    if (!_isAuthenticated) {
      return loadConversation();
    }

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl$endpointMyConversations/$conversationId/messages',
        ),
        headers: _authHeaders,
      );
      if (response.statusCode != 200) return const [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = data['messages'] as List<dynamic>? ?? const [];

      return raw.whereType<Map<String, dynamic>>().map((m) {
        return <String, String>{
          'role': (m['role'] as String?) ?? roleAssistant,
          'content': (m['content'] as String?) ?? '',
        };
      }).where((m) => m['content']!.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Send a message in a specific conversation.
  static Future<ApiResponse> sendConversationMessage(
    String conversationId,
    String message,
  ) async {
    // Fallback: use legacy single-session chat when not authenticated.
    if (!_isAuthenticated) {
      return sendMessage(message);
    }

    try {
      final response = await http.post(
        Uri.parse(
          '$_baseUrl$endpointMyConversations/$conversationId/messages',
        ),
        headers: {'Content-Type': 'application/json', ..._authHeaders},
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final opportunities = (data['opportunities'] as List<dynamic>?)
                ?.map(
                    (o) => Opportunity.fromJson(o as Map<String, dynamic>))
                .toList() ??
            <Opportunity>[];

        return ApiResponse(
          reply: (data['reply'] as String?) ??
              'Sorry, I could not process your request.',
          opportunities: opportunities,
        );
      } else {
        return ApiResponse(
          reply:
              'Error: Server returned status ${response.statusCode}. Please try again.',
        );
      }
    } catch (e) {
      return ApiResponse(
        reply:
            'Unable to connect to the server. Make sure the backend is running on $_baseUrl.',
      );
    }
  }

  // ─── Admin API ───

  static Future<List<Opportunity>> adminListOpportunities(
      String password) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$endpointAdminOpportunities'),
      headers: {'Authorization': 'Bearer $password'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['opportunities'] as List<dynamic>)
          .map((o) => Opportunity.fromJson(o as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Failed to load opportunities: ${response.statusCode}');
  }

  static Future<void> adminCreateOpportunity(
      String password, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpointAdminOpportunities'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $password',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create: ${response.body}');
    }
  }

  static Future<void> adminUpdateOpportunity(
      String password, String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$endpointAdminOpportunities/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $password',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update: ${response.body}');
    }
  }

  static Future<void> adminDeleteOpportunity(
      String password, String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$endpointAdminOpportunities/$id'),
      headers: {'Authorization': 'Bearer $password'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete: ${response.body}');
    }
  }
}
