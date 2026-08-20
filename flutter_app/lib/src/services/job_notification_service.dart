import 'package:dio/dio.dart';
import 'api_service.dart';

class JobNotification {
  final int id;
  final String examKey, titleTa, titleEn, status;
  final int? vacancies;
  final String? applicationStart, applicationEnd, examDate;
  final String applicationLink, officialLink;
  final String notesTa, notesEn;

  JobNotification.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        examKey = j['exam_key'] ?? '',
        titleTa = j['title_ta'] ?? '',
        titleEn = j['title_en'] ?? '',
        status = j['status'] ?? 'upcoming',
        vacancies = j['vacancies'],
        applicationStart = j['application_start'],
        applicationEnd = j['application_end'],
        examDate = j['exam_date'],
        applicationLink = j['application_link'] ?? '',
        officialLink = j['official_notification_link'] ?? '',
        notesTa = j['notes_ta'] ?? '',
        notesEn = j['notes_en'] ?? '';

  int? get daysLeft {
    if (applicationEnd == null) return null;
    try {
      final end = DateTime.parse(applicationEnd!);
      return end.difference(DateTime.now()).inDays;
    } catch (_) {
      return null;
    }
  }
}

class JobNotificationService {
  /// Only verified notifications are ever returned — see NotificationController backend note.
  static Future<List<JobNotification>> fetchAll() async {
    try {
      final res = await ApiService.instance.dio.get('/api/notifications');
      return (res.data['notifications'] as List)
          .map((j) => JobNotification.fromJson(j))
          .toList();
    } on DioException {
      return [];
    }
  }
}
