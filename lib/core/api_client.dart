import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// HTTP client that talks to the FastAPI backend.
class ApiClient {
  // Android emulator → host machine localhost
  // Change to your backend URL for physical devices
  static const String _baseUrl = 'http://10.44.98.135:8000';
  static const Duration _timeout = Duration(seconds: 15);

  /// POST /api/v1/chat/ask
  /// Returns decoded JSON map or `null` on failure / timeout.
  static Future<Map<String, dynamic>?> askQuestion({
    required String profileId,
    required String query,
    required String subject,
    required String language,
    required String learnerLevel,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/chat/ask');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'profile_id': profileId,
              'query': query,
              'subject': subject,
              'language': language,
              'learner_level': learnerLevel,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } on SocketException {
      // No internet — caller should switch to offline mode
      return null;
    } on http.ClientException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// POST /api/v1/chat/vision  (multipart image upload)
  /// Returns decoded JSON map or `null` on failure.
  static Future<Map<String, dynamic>?> sendVisionImage(File imageFile) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/chat/vision');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );

      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } on SocketException {
      return null;
    } on http.ClientException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Generic GET helper
  static Future<dynamic> get(String path) async {
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
