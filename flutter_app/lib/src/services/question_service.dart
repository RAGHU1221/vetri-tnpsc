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

  /// Options in the UI language; falls back to Tamil PER OPTION when the English
  /// text is missing/blank (imports often have empty option_*_en columns).
  List<String> optionsFor(bool ta) {
    if (ta) return optionsTa;
    return [
      for (int i = 0; i < optionsTa.length; i++)
        (i < optionsEn.length && optionsEn[i].trim().isNotEmpty) ? optionsEn[i] : optionsTa[i]
    ];
  }

  /// 🔥 3+, ⭐ 2, none otherwise
  String get importanceBadge =>
      repeatCount >= 3 ? '🔥' : (repeatCount == 2 ? '⭐' : '');
}

class QuestionService {
  static List<Question>? _cache;

  /// Drop the in-memory cache so the next call re-fetches from the server
  /// (used by the reload button / pull-to-refresh after admin imports).
  static void clearCache() => _cache = null;

  static Future<List<Question>> refresh() async {
    clearCache();
    return loadSeed();
  }

  /// Server-first (latest + admin-imported); seed JSON fallback offline.
  /// Loops through pages (backend caps each page at 500). If a later page fails,
  /// whatever was already fetched is kept instead of being thrown away.
  static Future<List<Question>>? _loading;

  /// Safe to call from many screens at once: only ONE network load runs.
  static Future<List<Question>> loadSeed() {
    if (_cache != null) return Future.value(_cache!);
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  static Future<List<Question>> _fetchPage(int offset, int size) async {
    final res = await ApiService.instance.dio.get('/api/questions',
        queryParameters: {'limit': size, 'offset': offset});
    return (res.data['questions'] as List).map((j) => Question.fromJson(j)).toList();
  }

  static Future<List<Question>> _load() async {
    final List<Question> all = [];
    try {
      const size = 500, wave = 3; // 3 pages in parallel per wave
      int offset = 0;
      bool done = false;
      while (!done) {
        final pages = await Future.wait([
          for (int i = 0; i < wave; i++) _fetchPage(offset + i * size, size),
        ]);
        for (final p in pages) {
          all.addAll(p);
          if (p.length < size) done = true;
        }
        offset += wave * size;
      }
    } catch (_) {
      // offline / partial failure - keep whatever arrived
    }
    if (all.isNotEmpty) return _cache = all;
    final raw = await rootBundle.loadString('assets/data/questions_seed.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return _cache = (data['questions'] as List).map((q) => Question.fromJson(q)).toList();
  }

  static String _key(String s) => s.trim().toLowerCase();

  /// subject -> questions for one exam group (subject keys normalised)
  static Future<Map<String, List<Question>>> bySubject({String? groupExam}) async {
    final all = await loadSeed();
    final filtered = groupExam == null ? all : all.where((q) => q.groupExam == groupExam).toList();
    final map = <String, List<Question>>{};
    for (final q in filtered) {
      map.putIfAbsent(_key(q.subject), () => []).add(q);
    }
    return map;
  }

  /// Questions of ONE subject inside one exam group (used by the question list)
  static Future<List<Question>> forSubject(String subject, {String? groupExam}) async {
    final m = await bySubject(groupExam: groupExam);
    return List<Question>.from(m[_key(subject)] ?? const []);
  }
}
