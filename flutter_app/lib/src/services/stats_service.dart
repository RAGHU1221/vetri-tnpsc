import 'package:dio/dio.dart';
import 'api_service.dart';

class StatsService {
  static Future<Map<String, dynamic>?> streakPing() async {
    try {
      final res = await ApiService.instance.dio.post('/api/streak/ping');
      return res.data;
    } on DioException {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> progress() async {
    try {
      final res = await ApiService.instance.dio.get('/api/progress');
      return res.data;
    } on DioException {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> leaderboard({String period = 'week'}) async {
    try {
      final res = await ApiService.instance.dio
          .get('/api/leaderboard', queryParameters: {'period': period});
      return res.data;
    } on DioException {
      return null;
    }
  }
}
