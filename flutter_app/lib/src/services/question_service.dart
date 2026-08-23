import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'api_service.dart';

class Question {
  final int id;
  final String groupExam;
  final String subject, unit, questionTa, questionEn;
  final String format; // simple | match_table | assertion_reason
  final List<String>? tableList1Ta, tableList2Ta, tableList1En, tableList2En;
  final String? assertionTa, assertionEn, reasonTa, reasonEn;
  final String? imageUrl;
  final bool sourceVerified;
  final List<String> optionsTa, optionsEn;
  final int correct;
  final String? bookTa, explanationTa, explanationEn;
  final int? pageNo;
  final List<String> yearsAsked;
  final int repeatCount;

  Question.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        groupExam = j['group_exam'] ?? 'G4',
        subject = j['subject'],
        unit = j['unit'] ?? '',
        questionTa = j['question_ta'],
        questionEn = j['question_en'] ?? '',
        format = j['question_format'] ?? j['format'] ?? 'simple',
        tableList1Ta = (j['table_data']?['list1_ta'] as List?)?.cast<String>() ??
            (j['table_list1_ta'] as List?)?.cast<String>(),
        tableList2Ta = (j['table_data']?['list2_ta'] as List?)?.cast<String>() ??
            (j['table_list2_ta'] as List?)?.cast<String>(),
        tableList1En = (j['table_data']?['list1_en'] as List?)?.cast<String>() ??
            (j['table_list1_en'] as List?)?.cast<String>(),
        tableList2En = (j['table_data']?['list2_en'] as List?)?.cast<String>() ??
            (j['table_list2_en'] as List?)?.cast<String>(),
        assertionTa = j['assertion_ta'],
        assertionEn = j['assertion_en'],
        reasonTa = j['reason_ta'],
        reasonEn = j['reason_en'],
        imageUrl = j['image_url'],
        sourceVerified = (j['source_verified'] ?? 0).toString() == '1',
        optionsTa = List<String>.from(j['options_ta']),
        optionsEn = List<String>.from(j['options_en'] ?? []),
        correct = j['correct'] ?? j['correct_option'],
        bookTa = j['book_ta'] ?? j['book_name_ta'],
        pageNo = j['page_no'],
        explanationTa = j['explanation_ta'],
        explanationEn = j['explanation_en'],
        yearsAsked = List<String>.from(j['years_asked'] ?? []),
        repeatCount = j['repeat_count'] ?? (j['years_asked']?.length ?? 0);

  /// 🔥 3+, ⭐ 2, none otherwise
  String get importanceBadge =>
      repeatCount >= 3 ? '🔥' : (repeatCount == 2 ? '⭐' : '');
}

class QuestionService {
  static List<Question>? _cache;

  /// Admin panel-la import pannadhum, already-running app-oda cache-a
  /// force clear panna. Aprom loadSeed()/bySubject() next call automatic-a
  /// server-kitta fresh data eduthukum.
  static void clearCache() => _cache = null;

  /// Cache clear panni udane server-la irundhu fresh-a reload pannum.
  static Future<List<Question>> refresh() {
    clearCache();
    return loadSeed();
  }

  /// Server-first (latest + admin-imported); seed JSON fallback offline
  static Future<List<Question>> loadSeed() async {
    if (_cache != null) return _cache!;
    try {
      // Loop through pages of 500 (server's max per-request cap) until every
      // question is fetched — works correctly no matter how many questions
      // exist in the DB now or after future imports (871, 2000, etc.).
      final all = <Question>[];
      const pageSize = 500;
      int offset = 0;
      while (true) {
        final res = await ApiService.instance.dio.get('/api/questions',
            queryParameters: {'limit': pageSize, 'offset': offset});
        final page = (res.data['questions'] as List)
            .map((j) => Question.fromJson(j))
            .toList();
        all.addAll(page);
        if (page.length < pageSize) break; // last page reached
        offset += pageSize;
      }
      if (all.isNotEmpty) return _cache = all;
    } catch (_) {
      // offline / cold start — seed asset fallback
    }
    try {
      final raw = await rootBundle.loadString('assets/data/questions_seed.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _cache = (data['questions'] as List)
          .map((q) => Question.fromJson(q))
          .toList();
      return _cache!;
    } catch (_) {
      // Bundled seed missing/unreadable and API unreachable — return empty
      // rather than crash; screens should handle an empty question list.
      return _cache = [];
    }
  }

  static Future<Map<String, List<Question>>> bySubject({String? groupExam}) async {
    final all = await loadSeed();
    final filtered = groupExam == null ? all : all.where((q) => q.groupExam == groupExam).toList();
    final map = <String, List<Question>>{};
    for (final q in filtered) {
      map.putIfAbsent(q.subject, () => []).add(q);
    }
    return map;
  }
}
