import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../widgets/session_manager.dart';

class ApiClient {
  // public ip for the server on aws
  static const String baseUrl = 'http://98.84.183.81:5000';

  static Future<Map<String, String>> _getHeaders({
    bool requireAuth = false,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    if (requireAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requireAuth = false,
    String? customToken,
  }) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      if (customToken != null) {
        headers['Authorization'] = 'Bearer $customToken';
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _decodeResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requireAuth = false,
  }) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: headers)
          .timeout(const Duration(seconds: 10));

      return _decodeResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    }
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.statusCode == 401) {
      debugPrint('[SECURITY-WALL] 401 Unauthorized detected.');
      SessionManager.forceLogout();
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final data = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : {'success': true, 'data': decoded};
      return {...data, 'statusCode': response.statusCode};
    } else {
      try {
        final decoded = jsonDecode(response.body);
        final body = decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : <String, dynamic>{};
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message':
              body['message']?.toString() ?? 'Error ${response.statusCode}',
          ...body,
        };
      } catch (_) {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'HTTP Error: ${response.statusCode}',
        };
      }
    }
  }
}
