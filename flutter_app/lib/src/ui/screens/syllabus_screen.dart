import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
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
        subject = _normalizeSubject(j['subject']),
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

  /// DB-la subject column-ku Tamil-script vs English-spelling variants
  /// (e.g. "தமிழ்" vs "tamil") separate values-a store aagi, app-la
  /// rendum vera vera map keys-a split aagi silent-a hide aaguthu.
  /// Idha thavirkka, load pannumbodhே canonical (English) spelling-ku
  /// normalize pannurom — DB-la future-la இதே மாதிரி typo/variant
  /// vandhalum UI break aagaadhu.
  static String _normalizeSubject(String raw) {
    const map = {
      'தமிழ்': 'tamil',
      // Future-la இதே மாதிரி Tamil-script duplicate subject values
      // kandupidichaal, இங்க add pannunga:
      // 'பொருளாதாரம்': 'economy',
      // 'வரலாறு': 'history',
      // 'புவியியல்': 'geography',
      // 'அறிவியல்': 'science',
      // 'அரசியல்': 'polity',
      // 'நடப்பு நிகழ்வுகள்': 'current_affairs',
      // 'திறன்': 'aptitude',
    };
    return map[raw] ?? raw;
  }

  /// 🔥 3+, ⭐ 2, none otherwise
  String get importanceBadge =>
      repeatCount >= 3 ? '🔥' : (repeatCount == 2 ? '⭐' : '');
}

class QuestionService {
  static List<Question>? _cache;

  /// The real exception from the last failed live fetch, if the app had to
  /// fall back to the bundled seed asset. Null when the last load came
  /// from the live server successfully. Screens can show this on-screen
  /// (SnackBar/banner) so the actual cause is visible on the phone itself,
  /// without needing adb logcat / a computer.
  static String? lastError;

  /// True if the questions currently in memory came from the bundled
  /// offline seed file rather than the live server (i.e. the counts you
  /// see may be outdated / missing recent admin imports).
  static bool usedSeedFallback = false;

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
      var skipped = 0;

      while (true) {
        final res = await ApiService.instance.dio.get(
          '/api/questions',
          queryParameters: {
            'limit': pageSize,
            'offset': offset,
          },
        );

        final rawPage = res.data['questions'] as List;

        // Parse each row individually — a single malformed/unexpected row
        // (missing field, new admin-import edge case, etc.) used to throw
        // inside .map() and abort the ENTIRE fetch, silently falling back
        // to the old bundled seed JSON for ALL groups/subjects. Now we
        // skip just that one row and keep the rest of the (correct) live
        // data, and log exactly which question id + error caused it so
        // it can be fixed at the source (import script / DB row).
        for (final j in rawPage) {
          try {
            all.add(
              Question.fromJson(j as Map<String, dynamic>),
            );
          } catch (e) {
            skipped++;

            debugPrint(
              'QuestionService: skipped malformed question '
              'id=${j is Map ? j['id'] : '?'} — $e',
            );
          }
        }

        if (rawPage.length < pageSize) {
          break;
        }

        offset += pageSize;
      }

      if (skipped > 0) {
        debugPrint(
          'QuestionService: loaded ${all.length} questions, '
          'skipped $skipped malformed rows '
          '(see logs above for ids)',
        );
      }

      if (all.isNotEmpty) {
        lastError = null;
        usedSeedFallback = false;
        return _cache = all;
      }
    } catch (e, st) {
      // Network/API-level failure (server down, timeout, auth, etc.) —
      // fall back to bundled seed asset. Stored in lastError so a screen
      // can show it on-screen (no adb/computer needed to see why).
      lastError = e.toString();

      debugPrint(
        'QuestionService: live fetch failed, '
        'falling back to bundled seed — $e',
      );

      debugPrint('$st');
    }

    usedSeedFallback = true;

    try {
      final raw = await rootBundle.loadString(
        'assets/data/questions_seed.json',
      );

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final seedList = data['questions'] as List;
      final seedQuestions = <Question>[];

      for (final q in seedList) {
        try {
          seedQuestions.add(
            Question.fromJson(q as Map<String, dynamic>),
          );
        } catch (e) {
          debugPrint(
            'QuestionService: skipped malformed seed question — $e',
          );
        }
      }

      _cache = seedQuestions;
      return _cache!;
    } catch (e) {
      // Bundled seed missing/unreadable and API unreachable — return empty
      // rather than crash; screens should handle an empty question list.
      lastError = e.toString();

      debugPrint(
        'QuestionService: bundled seed also failed to load — $e',
      );

      return _cache = [];
    }
  }

  static Future<Map<String, List<Question>>> bySubject({
    String? groupExam,
  }) async {
    final all = await loadSeed();

    final filtered = groupExam == null
        ? all
        : all.where((q) => q.groupExam == groupExam).toList();

    final map = <String, List<Question>>{};

    for (final q in filtered) {
      map.putIfAbsent(q.subject, () => []).add(q);
    }

    return map;
  }
}
