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

  // ─── Core chat API (single-session) ───

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

  static Future<List<Map<String, dynamic>>> listConversations() async {
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

  static Future<Map<String, dynamic>?> createConversation({
    String title = 'New chat',
  }) async {
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

  static Future<bool> deleteConversation(String conversationId) async {
    if (!_isAuthenticated) {
      // In unauthenticated mode we have only one "current chat" tied to the
      // fallback session id. Deleting it should reset the local session so the
      // old messages won't load again after refresh.
      const fallbackKey = 'pathora_fallback_session';
      web.window.localStorage.removeItem(fallbackKey);
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

  static Future<bool> renameConversation(
    String conversationId,
    String title,
  ) async {
    if (!_isAuthenticated) {
      // Don't pretend this succeeded; without auth we can't persist the rename.
      return false;
    }

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl$endpointMyConversations/$conversationId'),
        headers: {'Content-Type': 'application/json', ..._authHeaders},
        body: jsonEncode({'title': title}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, String>>> loadConversationMessages(
    String conversationId,
  ) async {
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

  static Future<ApiResponse> sendConversationMessage(
    String conversationId,
    String message,
  ) async {
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

  // ─── Sharing API ───

  static Future<String?> createShareLink(String conversationId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpointMyConversations/$conversationId/share'),
        headers: _authHeaders,
      );
      if (response.statusCode != 201) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final shareId = data['shareId'] as String?;
      if (shareId == null || shareId.isEmpty) return null;

      final origin = web.window.location.origin;
      return '$origin$routeShareChat/$shareId';
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, String>>> loadSharedConversation(
    String shareId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$endpointSharePublic/$shareId'),
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
}
