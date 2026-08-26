import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ExamGuide {
  final String examKey, category, icon, colorHex;
  final String nameTa, nameEn;
  final String conductingBodyTa, conductingBodyEn;
  final String eligibilityTa, eligibilityEn;
  final String ageLimitTa, ageLimitEn;
  final String examPatternTa, examPatternEn;
  final String syllabusTa, syllabusEn;
  final String selectionProcessTa, selectionProcessEn;
  final String salaryTa, salaryEn;
  final String officialWebsite;
  final String prepTipsTa, prepTipsEn;

  ExamGuide.fromJson(Map<String, dynamic> j)
      : examKey = j['exam_key'] ?? '',
        category = j['category'] ?? 'govt_job',
        icon = j['icon'] ?? '📋',
        colorHex = j['color_hex'] ?? '#2E7D4F',
        nameTa = j['name_ta'] ?? '',
        nameEn = j['name_en'] ?? '',
        conductingBodyTa = j['conducting_body_ta'] ?? '',
        conductingBodyEn = j['conducting_body_en'] ?? '',
        eligibilityTa = j['eligibility_ta'] ?? '',
        eligibilityEn = j['eligibility_en'] ?? '',
        ageLimitTa = j['age_limit_ta'] ?? '',
        ageLimitEn = j['age_limit_en'] ?? '',
        examPatternTa = j['exam_pattern_ta'] ?? '',
        examPatternEn = j['exam_pattern_en'] ?? '',
        syllabusTa = j['syllabus_ta'] ?? '',
        syllabusEn = j['syllabus_en'] ?? '',
        selectionProcessTa = j['selection_process_ta'] ?? '',
        selectionProcessEn = j['selection_process_en'] ?? '',
        salaryTa = j['salary_ta'] ?? '',
        salaryEn = j['salary_en'] ?? '',
        officialWebsite = j['official_website'] ?? '',
        prepTipsTa = j['prep_tips_ta'] ?? '',
        prepTipsEn = j['prep_tips_en'] ?? '';

  List<String> get syllabusListTa => syllabusTa.split('\n').where((s) => s.trim().isNotEmpty).toList();
  List<String> get syllabusListEn => syllabusEn.split('\n').where((s) => s.trim().isNotEmpty).toList();
  List<String> get patternListTa => examPatternTa.split('\n').where((s) => s.trim().isNotEmpty).toList();
  List<String> get patternListEn => examPatternEn.split('\n').where((s) => s.trim().isNotEmpty).toList();
}

class GuideService {
  static List<ExamGuide>? _cache;

  static Future<List<ExamGuide>> loadAll() async {
    if (_cache != null) return _cache!;
    // Guide content (syllabus, eligibility, exam pattern, etc.) is served
    // from the bundled asset. The /api/guides list endpoint only returns
    // summary fields (no syllabus/eligibility/exam_pattern), so it can't
    // fully populate ExamGuide — using it here would silently blank out
    // those sections on the detail screen. Until a live endpoint returns
    // the full guide payload, the bundled asset is the single source of
    // truth; update assets/data/exam_guides.json to change guide content.
    try {
      final raw = await rootBundle.loadString('assets/data/exam_guides.json');
      final list = (jsonDecode(raw) as List).map((g) => ExamGuide.fromJson(g)).toList();
      return _cache = list;
    } catch (_) {
      // Asset missing/unreadable — never crash the app over guide content.
      return _cache = [];
    }
  }

  static Future<Map<String, List<ExamGuide>>> byCategory() async {
    final all = await loadAll();
    final map = <String, List<ExamGuide>>{};
    for (final g in all) {
      map.putIfAbsent(g.category, () => []).add(g);
    }
    return map;
  }
}
