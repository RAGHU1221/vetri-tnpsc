import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/question_service.dart';
import '../../services/test_service.dart';
import '../widgets/vetri_buttons.dart';
import 'syllabus_screen.dart';

class TestResultScreen extends StatelessWidget {
  final TestResult result;
  final List<Question> questions;
  final Map<int, int> answers;
  final bool autoSubmitted;
  const TestResultScreen(
      {super.key, required this.result, required this.questions,
       required this.answers, this.autoSubmitted = false});

  @override
  Widget build(BuildContext context) {
    final ta = context.watch<AppProvider>().isTamil;
    final pass = result.accuracy >= 45; // G4 qualifying ~90/300 = 30%; safe target 45%
    return Scaffold(
      appBar: AppBar(
        title: Text(ta ? 'முடிவு' : 'Result'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => context.go('/dashboard')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (autoSubmitted)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFF6DC),
                  borderRadius: BorderRadius.circular(9)),
              child: Text(ta
                  ? '⏰ நேரம் முடிந்ததால் தானாக சமர்ப்பிக்கப்பட்டது'
                  : '⏰ Auto-submitted — time over'),
            ),
          // Score card
          Card(
            color: pass ? const Color(0xFFEDF7F0) : const Color(0xFFFDECEA),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text(pass ? '🏆' : '💪', style: const TextStyle(fontSize: 44)),
                  Text(
                      '${result.score.toStringAsFixed(1)} / ${(result.total * 1.5).toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 34, fontWeight: FontWeight.w800)),
                  Text(ta ? 'மதிப்பெண்கள்' : 'Marks'),
                  const SizedBox(height: 8),
                  Text(
                      '${ta ? "துல்லியம்" : "Accuracy"}: ${result.accuracy.toStringAsFixed(1)}%'
                      '${result.percentile != null ? "  ·  ${ta ? "சதவீதநிலை" : "Percentile"}: ${result.percentile}" : ""}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _stat(ta ? 'சரி' : 'Correct', result.correct, const Color(0xFF2E7D4F)),
              _stat(ta ? 'தவறு' : 'Wrong', result.wrong, const Color(0xFFB33A2B)),
              _stat(ta ? 'விடுபட்டவை' : 'Skipped', result.skipped, Colors.grey),
            ],
          ),
          if (result.weakSubjects.isNotEmpty) ...[
            const SizedBox(height: 14),
            Card(
              color: const Color(0xFFFFF9E8),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ta ? '📌 கவனம் தேவையான பாடங்கள்:' : '📌 Weak areas to focus:',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final s in result.weakSubjects)
                          Chip(label: Text(ta
                              ? (SyllabusScreen.names[s]?.$1 ?? s)
                              : (SyllabusScreen.names[s]?.$2 ?? s))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(ta ? '📖 விடைகள் & விளக்கம்' : '📖 Solutions & explanations',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 8),
          for (int i = 0; i < questions.length; i++) _solution(context, i, ta),
        ],
      ),
    );
  }

  Widget _stat(String label, int v, Color c) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(children: [
              Text('$v',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: c)),
              Text(label, style: const TextStyle(fontSize: 12)),
            ]),
          ),
        ),
      );

  Widget _solution(BuildContext context, int i, bool ta) {
    final q = questions[i];
    final ans = answers[i];
    final isCorrect = ans == q.correct;
    final options = ta || q.optionsEn.isEmpty ? q.optionsTa : q.optionsEn;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: Icon(
            ans == null
                ? Icons.remove_circle_outline
                : isCorrect
                    ? Icons.check_circle
                    : Icons.cancel,
            color: ans == null
                ? Colors.grey
                : isCorrect
                    ? const Color(0xFF2E7D4F)
                    : const Color(0xFFB33A2B)),
        title: Text('${i + 1}. ${q.questionTa}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✔ ${ta ? "சரியான விடை" : "Correct"}: '
                    '${String.fromCharCode(65 + q.correct)}. ${options[q.correct]}',
                    style: const TextStyle(
                        color: Color(0xFF2E7D4F), fontWeight: FontWeight.w700)),
                if (ans != null && !isCorrect)
                  Text('✘ ${ta ? "உங்கள் விடை" : "Your answer"}: '
                      '${String.fromCharCode(65 + ans)}. ${options[ans]}',
                      style: const TextStyle(color: Color(0xFFB33A2B))),
                if ((q.explanationTa ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                        '💡 ${ta ? q.explanationTa : (q.explanationEn ?? q.explanationTa)}',
                        style: const TextStyle(fontSize: 13.5)),
                  ),
                if (q.bookTa != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                        '📖 ${q.bookTa}${q.pageNo != null ? " · ${ta ? "பக்கம்" : "p."} ${q.pageNo}" : ""}',
                        style: TextStyle(
                            fontSize: 12.5, color: Colors.grey.shade700)),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: VetriButton(
                    label: ta ? 'AI-யிடம் மேலும் கேள்' : 'Ask AI more',
                    icon: Icons.smart_toy_rounded,
                    style: VetriButtonStyle.gold,
                    fullWidth: false,
                    height: 40,
                    onPressed: () => context.push('/ai-chat',
                        extra:
                            'இந்த TNPSC கேள்வியை விளக்கு: ${q.questionTa} — சரியான விடை: ${options[q.correct]}. ஏன் இது சரி, மற்றவை ஏன் தவறு, ஒரு memory trick சொல்லு.'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
