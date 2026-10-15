import 'package:dio/dio.dart';
import 'api_service.dart';

class AIService {
  static String _err(Object e, String fallback) {
    if (e is DioException) {
      final d = e.response?.data;
      if (d is Map && d['error'] is String) return d['error'] as String;
      final c = e.response?.statusCode;
      if (c != null) return 'சேவையக பிழை (Server $c)';
    }
    return fallback;
  }

  static Future<String> chat(List<Map<String, String>> messages) async {
    try {
      final res = await ApiService.instance.dio.post('/api/ai/chat',
          data: {'messages': messages},
          options: Options(receiveTimeout: const Duration(seconds: 90)));
      return (res.data['reply'] as String?) ?? '';
    } catch (e) {
      return _err(e, 'இணைப்பு பிழை — சிறிது நேரம் கழித்து முயற்சிக்கவும்');
    }
  }

  static Future<String> explain(int questionId) async {
    try {
      final res = await ApiService.instance.dio.post('/api/ai/explain',
          data: {'question_id': questionId},
          options: Options(receiveTimeout: const Duration(seconds: 90)));
      return (res.data['reply'] as String?) ?? '';
    } catch (e) {
      return _err(e, 'இணைப்பு பிழை');
    }
  }
}
