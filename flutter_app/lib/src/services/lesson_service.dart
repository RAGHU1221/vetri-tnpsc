import 'api_service.dart';

class LessonSummary {
  final int id, lessonNo, passPercent;
  final String unit, lessonTitleTa;
  final bool locked, passed;
  final double? score;

  LessonSummary.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        lessonNo = j['lesson_no'],
        unit = j['unit'] ?? '',
        lessonTitleTa = j['lesson_title_ta'] ?? '',
        passPercent = j['pass_percent'] ?? 70,
        locked = j['locked'] ?? false,
        passed = j['passed'] ?? false,
        score = (j['score'] as num?)?.toDouble();
}

class LessonTestQuestion {
  final int id, questionNo;
  final String questionTa, optionA, optionB, optionC, optionD, correctOption;
  final String? explanationTa;

  LessonTestQuestion.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        questionNo = j['question_no'],
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
      : id = j['id'],
        lessonNo = j['lesson_no'],
        passPercent = j['pass_percent'] ?? 70,
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
      : correct = j['correct'],
        total = j['total'],
        passPercent = j['pass_percent'],
        scorePercent = (j['score_percent'] as num).toDouble(),
        passed = j['passed'];
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
