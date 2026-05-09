import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String _physicalDeviceUrl = 'http://172.18.116.80:8000';
  static String get _baseUrl => _physicalDeviceUrl;
  static const Duration _timeout = Duration(seconds: 3);

  static bool _backendReachable = true;
  static DateTime? _lastFailTime;

  static bool get shouldTryBackend {
    if (_backendReachable) return true;
    if (_lastFailTime != null && DateTime.now().difference(_lastFailTime!).inSeconds > 30) {
      _backendReachable = true;
      return true;
    }
    return false;
  }

  static void _markFailed() { _backendReachable = false; _lastFailTime = DateTime.now(); }
  static void _markSuccess() { _backendReachable = true; }

  static Future<Map<String, dynamic>?> askQuestion({
    required String profileId, required String query,
    String subject = 'General', String language = 'en-IN', String learnerLevel = 'Intermediate',
  }) async {
    if (!shouldTryBackend) return null;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/chat/ask'),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode({'profile_id': profileId, 'query': query, 'subject': subject, 'language': language, 'learner_level': learnerLevel}),
      ).timeout(_timeout);
      if (response.statusCode == 200) { _markSuccess(); return jsonDecode(response.body); }
      _markFailed(); return null;
    } catch (_) { _markFailed(); return null; }
  }

  static Future<String?> describeImage(String base64Image) async {
    if (!shouldTryBackend) return null;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/vision/describe'),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode({'image_base64': base64Image}),
      ).timeout(_timeout);
      if (response.statusCode == 200) { _markSuccess(); return (jsonDecode(response.body))['description']; }
      _markFailed(); return null;
    } catch (_) { _markFailed(); return null; }
  }
}
