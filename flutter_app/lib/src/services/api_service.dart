import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl;
  final Map<String, String> _headers;

  ApiService({required String baseUrl})
      : _baseUrl = baseUrl,
        _headers = {'Content-Type': 'application/json'};

  Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$path'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: response.reasonPhrase ?? 'Unknown error',
      body: response.body,
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String body;

  ApiException({
    required this.statusCode,
    required this.message,
    required this.body,
  });

  @override
  String toString() => 'ApiException($statusCode): $message\n$body';
}
