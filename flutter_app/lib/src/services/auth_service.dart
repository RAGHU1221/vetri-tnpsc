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
      final msg = e.response?.data?['error'];
      return (false, msg is String ? msg : 'இணைப்பு பிழை / Connection error');
    }
  }

  Future<(bool, String)> register(String name, String mobile, String password) async {
    try {
      final res = await _api.dio.post('/api/auth/register',
          data: {'name': name, 'mobile': mobile, 'password': password});
      await _api.saveToken(res.data['token']);
      return (true, 'success');
    } on DioException catch (e) {
      final msg = e.response?.data?['error'];
      return (false, msg is String ? msg : 'இணைப்பு பிழை / Connection error');
    }
  }

  Future<void> logout() => _api.clearToken();
  Future<bool> isLoggedIn() async => await _api.getToken() != null;
}
