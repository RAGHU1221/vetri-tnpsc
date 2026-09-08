import 'package:dio/dio.dart';
import 'api_service.dart';

class StudyNote {
  final int id;
  final String category, titleTa, titleEn, contentTa, contentEn;
  final String? noteDate;
  StudyNote.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        category = j['category'] ?? 'general',
        titleTa = j['title_ta'] ?? '',
        titleEn = j['title_en'] ?? '',
        contentTa = j['content_ta'] ?? '',
        contentEn = j['content_en'] ?? '',
        noteDate = j['note_date'];
}

class NotesService {
  static Future<List<StudyNote>> fetch({String? category}) async {
    try {
      final res = await ApiService.instance.dio.get('/api/notes',
          queryParameters: {if (category != null) 'category': category});
      return (res.data['notes'] as List)
          .map((j) => StudyNote.fromJson(j))
          .toList();
    } on DioException {
      return [];
    }
  }
}
