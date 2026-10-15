import 'package:dio/dio.dart';
import 'api_service.dart';

class AuthService {
  final _api = ApiService.instance;

  Future<(bool, String)> login(String mobile, String password) async {
    try {
      final res = await _api.dio.post('/api/auth/login',
          data: {'mobile': mobile, 'password': password});
      await _api.saveToken(res.data['token']);
      return (true, 'success');
    } on DioException catch (e) {
      return (false, (e.response?.data?['error'] as String?) ?? 'இணைப்பு பிழை / Connection error');
    }
  }

  Future<(bool, String)> register(String name, String mobile, String password) async {
    try {
      final res = await _api.dio.post('/api/auth/register',
          data: {'name': name, 'mobile': mobile, 'password': password});
      await _api.saveToken(res.data['token']);
      return (true, 'success');
    } on DioException catch (e) {
      return (false, (e.response?.data?['error'] as String?) ?? 'இணைப்பு பிழை / Connection error');
    }
  }

  Future<(bool, String)> forgotPassword(String mobile, String name, String newPassword) async {
    try {
      await _api.dio.post('/api/auth/forgot',
          data: {'mobile': mobile, 'name': name, 'new_password': newPassword});
      return (true, 'success');
    } on DioException catch (e) {
      return (false, (e.response?.data?['error'] as String?) ?? 'இணைப்பு பிழை / Connection error');
    }
  }

  Future<void> logout() => _api.clearToken();
  Future<bool> isLoggedIn() async => await _api.getToken() != null;
}
