import 'api_service.dart';

/// PHP/PDO (with the default "emulated prepares" mode) sometimes returns
/// numeric DB columns as JSON strings instead of JSON numbers, depending on
/// whether that specific endpoint explicitly cast them. Parsing with a
/// plain `j['id']` assignment to an `int` field crashes the whole request
/// the moment that happens (exactly what broke "open Lesson 2" — the
/// server-side fix is in LessonController::detail(), but parsing
/// defensively here means a similar oversight elsewhere never takes the
/// whole screen down again).
int _toInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

double _toDouble(dynamic v, [double fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

class LessonSummary {
  final int id, lessonNo, passPercent;
  final String unit, lessonTitleTa;
  final bool locked, passed;
  final double? score;

  LessonSummary.fromJson(Map<String, dynamic> j)
      : id = _toInt(j['id']),
        lessonNo = _toInt(j['lesson_no']),
        unit = j['unit'] ?? '',
        lessonTitleTa = j['lesson_title_ta'] ?? '',
        passPercent = _toInt(j['pass_percent'], 70),
        locked = j['locked'] ?? false,
        passed = j['passed'] ?? false,
        score = j['score'] == null ? null : _toDouble(j['score']);
}

class LessonTestQuestion {
  final int id, questionNo;
  final String questionTa, optionA, optionB, optionC, optionD, correctOption;
  final String? explanationTa;

  LessonTestQuestion.fromJson(Map<String, dynamic> j)
      : id = _toInt(j['id']),
        questionNo = _toInt(j['question_no']),
        questionTa = j['question_ta'] ?? '',
        optionA = j['option_a'] ?? '',
        optionB = j['option_b'] ?? '',
        optionC = j['option_c'] ?? '',
        optionD = j['option_d'] ?? '',
        correctOption = j['correct_option'] ?? '',
        explanationTa = j['explanation_ta'];

  List<MapEntry<String, String>> get options => [
        MapEntry('A', optionA),
        MapEntry('B', optionB),
        MapEntry('C', optionC),
        MapEntry('D', optionD),
      ];
}

class LessonDetail {
  final int id, lessonNo, passPercent;
  final String unit, lessonTitleTa;
  final String? explanationTa, importantPointsTa, sampleQuestionTa,
      sampleCorrectAnswerTa, sampleQuestionExplanationTa;
  final List<String>? sampleOptions;
  final List<LessonTestQuestion> tests;

  LessonDetail.fromJson(Map<String, dynamic> j)
      : id = _toInt(j['id']),
        lessonNo = _toInt(j['lesson_no']),
        passPercent = _toInt(j['pass_percent'], 70),
        unit = j['unit'] ?? '',
        lessonTitleTa = j['lesson_title_ta'] ?? '',
        explanationTa = j['explanation_ta'],
        importantPointsTa = j['important_points_ta'],
        sampleQuestionTa = j['sample_question_ta'],
        sampleCorrectAnswerTa = j['sample_correct_answer_ta'],
        sampleQuestionExplanationTa = j['sample_question_explanation_ta'],
        sampleOptions = (j['sample_options_ta'] as List?)?.map((e) => e.toString()).toList(),
        tests = (j['tests'] as List? ?? []).map((t) => LessonTestQuestion.fromJson(t)).toList();

  /// முக்கியமான குறிப்புகள் bullet list-ஆக பிரிக்க — source-ல் newline-separated.
  List<String> get importantPointsList => (importantPointsTa ?? '')
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

class LessonTestResult {
  final int correct, total, passPercent;
  final double scorePercent;
  final bool passed;

  LessonTestResult.fromJson(Map<String, dynamic> j)
      : correct = _toInt(j['correct']),
        total = _toInt(j['total']),
        passPercent = _toInt(j['pass_percent']),
        scorePercent = _toDouble(j['score_percent']),
        passed = j['passed'] == true || j['passed'] == 1 || j['passed'] == '1';
}

class LessonService {
  static const groupExam = 'G4';
  static const subjectTa = 'தமிழ் தகுதி மற்றும் மதிப்பீட்டுத் தேர்வு';

  static Future<List<LessonSummary>> list() async {
    final res = await ApiService.instance.dio.get('/api/lessons',
        queryParameters: {'group_exam': groupExam, 'subject': subjectTa});
    return (res.data['lessons'] as List).map((j) => LessonSummary.fromJson(j)).toList();
  }

  static Future<LessonDetail> detail(int id) async {
    final res = await ApiService.instance.dio.get('/api/lessons/$id');
    return LessonDetail.fromJson(res.data['lesson']);
  }

  /// answers: {question_id: 'A'|'B'|'C'|'D'}
  static Future<LessonTestResult> submit(int lessonId, Map<int, String> answers) async {
    final res = await ApiService.instance.dio.post('/api/lessons/$lessonId/submit',
        data: {'answers': answers.map((k, v) => MapEntry(k.toString(), v))});
    return LessonTestResult.fromJson(res.data);
  }
}
