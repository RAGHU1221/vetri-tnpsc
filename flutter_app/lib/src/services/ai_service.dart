import 'package:dio/dio.dart';
import 'api_service.dart';

class AIService {
  static Future<String> chat(List<Map<String, String>> messages) async {
    try {
      final res = await ApiService.instance.dio
          .post('/api/ai/chat', data: {'messages': messages});
      return res.data['reply'] ?? '';
    } on DioException catch (e) {
      return (e.response?.data?['error'] as String?) ??
          'இணைப்பு பிழை — சிறிது நேரம் கழித்து முயற்சிக்கவும்';
    }
  }

  static Future<String> explain(int questionId) async {
    try {
      final res = await ApiService.instance.dio
          .post('/api/ai/explain', data: {'question_id': questionId});
      return res.data['reply'] ?? '';
    } on DioException catch (e) {
      return (e.response?.data?['error'] as String?) ?? 'இணைப்பு பிழை';
    }
  }
}
