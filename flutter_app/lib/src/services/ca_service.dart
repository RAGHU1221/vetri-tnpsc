import 'package:dio/dio.dart';
import 'api_service.dart';

class CAItem {
  final String date, category, titleTa, titleEn, contentTa, contentEn;
  final bool isTn;
  CAItem.fromJson(Map<String, dynamic> j)
      : date = j['ca_date'] ?? '',
        category = j['category'] ?? 'general',
        titleTa = j['title_ta'] ?? '',
        titleEn = j['title_en'] ?? '',
        contentTa = j['content_ta'] ?? '',
        contentEn = j['content_en'] ?? '',
        isTn = (j['is_tn'] ?? 0).toString() == '1';
}

class CAService {
  static Future<List<CAItem>> fetch({String? month, bool tnOnly = false}) async {
    try {
      final res = await ApiService.instance.dio.get('/api/current-affairs',
          queryParameters: {
            if (month != null) 'month': month,
            if (tnOnly) 'tn': 1,
          });
      return (res.data['items'] as List)
          .map((j) => CAItem.fromJson(j))
          .toList();
    } on DioException {
      return [];
    }
  }
}
