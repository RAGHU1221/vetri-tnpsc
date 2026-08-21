import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
        final token = await getToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
    ));

  // Secure storage (Android Keystore-backed) can throw PlatformException on
  // some devices/first-launch scenarios. This runs on every app start (via
  // the router's login check), so every call is guarded — a storage failure
  // should never crash the app, just be treated as "not logged in".
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: 'token', value: token);
    } catch (e) {
      debugPrint('SecureStorage write failed (non-fatal): $e');
    }
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: 'token');
    } catch (e) {
      debugPrint('SecureStorage read failed (non-fatal): $e');
      return null;
    }
  }

  Future<void> clearToken() async {
    try {
      await _storage.delete(key: 'token');
    } catch (e) {
      debugPrint('SecureStorage delete failed (non-fatal): $e');
    }
  }
}
