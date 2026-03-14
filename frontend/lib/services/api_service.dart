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
    defaultValue: 'http://127.0.0.1:3000',
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
