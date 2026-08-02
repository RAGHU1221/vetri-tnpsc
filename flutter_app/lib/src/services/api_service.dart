import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const _storage = FlutterSecureStorage();

  late final Dio dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 60), // Render cold start
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ))
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'token');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
    ));

  Future<void> saveToken(String token) => _storage.write(key: 'token', value: token);
  Future<String?> getToken() => _storage.read(key: 'token');
  Future<void> clearToken() => _storage.delete(key: 'token');
}
