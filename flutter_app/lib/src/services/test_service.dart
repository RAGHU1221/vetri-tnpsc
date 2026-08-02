import 'dart:math';
import 'package:dio/dio.dart';
import 'api_service.dart';
import 'question_service.dart';

class TestConfig {
  final String type;        // 'mini' | 'full' | 'daily'
  final String? subject;    // null = all subjects
  final String groupExam;   // 'G4' | 'G2A'
  final int count;
  final Duration duration;
  TestConfig({required this.type, this.subject, this.groupExam = 'G4', required this.count, required this.duration});
}

class TestResult {
  final int total, correct, wrong, skipped;
  final double score, accuracy;
  final Duration timeTaken;
  final List<String> weakSubjects;
  final double? percentile;
  TestResult({required this.total, required this.correct, required this.wrong,
      required this.skipped, required this.score, required this.accuracy,
      required this.timeTaken, required this.weakSubjects, this.percentile});
}

class TestService {
  /// Random questions select — important (repeat_count) weightage-oda
  static Future<List<Question>> buildTest(TestConfig cfg) async {
    final all = await QuestionService.loadSeed();
    var pool = all.where((q) => q.groupExam == cfg.groupExam).toList();
    if (cfg.subject != null) {
      pool = pool.where((q) => q.subject == cfg.subject).toList();
    }
    pool = List.of(pool)..shuffle(Random());
    // 🔥 important questions 40% priority
    pool.sort((a, b) {
      final r = Random().nextDouble();
      return r < 0.4 ? b.repeatCount.compareTo(a.repeatCount) : 0;
    });
    return pool.take(cfg.count).toList();
  }

  /// Score calculate + weak subjects + server submit
  static Future<TestResult> evaluate(
      TestConfig cfg, List<Question> questions, Map<int, int> answers, Duration timeTaken) async {
    int correct = 0, wrong = 0;
    final subjectWrong = <String, int>{}, subjectTotal = <String, int>{};
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      subjectTotal[q.subject] = (subjectTotal[q.subject] ?? 0) + 1;
      if (!answers.containsKey(i)) continue;
      if (answers[i] == q.correct) {
        correct++;
      } else {
        wrong++;
        subjectWrong[q.subject] = (subjectWrong[q.subject] ?? 0) + 1;
      }
    }
    final skipped = questions.length - correct - wrong;
    // Weak: >40% wrong in that subject
    final weak = subjectWrong.entries
        .where((e) => e.value / subjectTotal[e.key]! > 0.4)
        .map((e) => e.key)
        .toList();
    final score = correct * 1.5; // G4: 1.5 marks per question
    double? percentile;
    try {
      final res = await ApiService.instance.dio.post('/api/tests/submit', data: {
        'test_type': cfg.type,
        'subject': cfg.subject,
        'total': questions.length,
        'correct': correct,
        'wrong': wrong,
        'skipped': skipped,
        'time_taken_sec': timeTaken.inSeconds,
        'weak_subjects': weak,
      });
      percentile = (res.data['percentile'] as num?)?.toDouble();
    } on DioException {
      // offline — local result mattum
    }
    return TestResult(
        total: questions.length, correct: correct, wrong: wrong, skipped: skipped,
        score: score, accuracy: correct / questions.length * 100,
        timeTaken: timeTaken, weakSubjects: weak, percentile: percentile);
  }
}
