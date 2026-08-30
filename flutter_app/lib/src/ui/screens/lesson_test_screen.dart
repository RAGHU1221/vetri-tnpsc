import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/lesson_service.dart';

class LessonTestScreen extends StatefulWidget {
  final LessonDetail lesson;
  const LessonTestScreen({super.key, required this.lesson});
  @override
  State<LessonTestScreen> createState() => _LessonTestScreenState();
}

class _LessonTestScreenState extends State<LessonTestScreen> {
  final Map<int, String> _answers = {}; // question_id -> 'A'..'D'
  int _current = 0;
  bool _submitting = false;
  LessonTestResult? _result;

  static const _optColors = {
    'A': Color(0xFF3E6FB0), 'B': Color(0xFF6B4FA0),
    'C': Color(0xFFD97B29), 'D': Color(0xFF2E7D4F),
  };

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final r = await LessonService.submit(widget.lesson.id, _answers);
      if (!mounted) return;
      setState(() => _result = r);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ta = context.watch<AppProvider>().isTamil;
    if (_result != null) return _ResultView(result: _result!, ta: ta, lesson: widget.lesson);

    final tests = widget.lesson.tests;
    final q = tests[_current];
    final answered = _answers[q.id];

    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EE),
      appBar: AppBar(
        title: Text(ta ? 'வினா ${_current + 1} / ${tests.length}' : 'Q ${_current + 1} / ${tests.length}'),
        elevation: 0,
      ),
      body: Column(
        children: [
          ClipRRect(
            child: LinearProgressIndicator(
              value: (_current + 1) / tests.length,
              minHeight: 5,
              backgroundColor: const Color(0xFFF1ECDD),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2E7D4F)),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Text(q.questionTa, style: const TextStyle(fontSize: 17, height: 1.5, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 16),
                for (final opt in q.options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OptionTile(
                      letter: opt.key,
                      text: opt.value,
                      color: _optColors[opt.key]!,
                      selected: answered == opt.key,
                      onTap: () => setState(() => _answers[q.id] = opt.key),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_current > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _current--),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: Text(ta ? 'முந்தையது' : 'Previous'),
                      ),
                    ),
                  if (_current > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: answered == null
                          ? null
                          : () {
                              if (_current < tests.length - 1) {
                                setState(() => _current++);
                              } else {
                                _submit();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D4F), foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _submitting
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              _current < tests.length - 1
                                  ? (ta ? 'அடுத்தது' : 'Next')
                                  : (ta ? 'சமர்ப்பிக்க' : 'Submit'),
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String letter, text;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _OptionTile({required this.letter, required this.text, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withOpacity(.1) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? color : const Color(0xFFE5E0D2), width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              CircleAvatar(radius: 15, backgroundColor: selected ? color : const Color(0xFFF1ECDD),
                  child: Text(letter, style: TextStyle(color: selected ? Colors.white : const Color(0xFF14213D), fontWeight: FontWeight.w800))),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 15, height: 1.4))),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final LessonTestResult result;
  final LessonDetail lesson;
  final bool ta;
  const _ResultView({required this.result, required this.lesson, required this.ta});

  @override
  Widget build(BuildContext context) {
    final passed = result.passed;
    return Scaffold(
      backgroundColor: passed ? const Color(0xFFEFF8F1) : const Color(0xFFFDF0EE),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(passed ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                  size: 84, color: passed ? const Color(0xFF2E7D4F) : const Color(0xFFB33A2B)),
              const SizedBox(height: 20),
              Text(
                passed
                    ? (ta ? '🎉 வாழ்த்துகள்! பாஸ் ஆனீர்கள்' : '🎉 Congratulations! You passed')
                    : (ta ? 'இன்னும் கொஞ்சம் practice பண்ணுங்க' : 'A bit more practice needed'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              Text('${result.correct} / ${result.total} ${ta ? "சரியானவை" : "correct"}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${result.scorePercent.toStringAsFixed(0)}% (${ta ? "தேவை" : "need"} ${result.passPercent}%)',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              const SizedBox(height: 8),
              if (passed)
                Text(ta ? '✓ அடுத்த பாடம் திறக்கப்பட்டது' : '✓ Next lesson unlocked',
                    style: const TextStyle(color: Color(0xFF2E7D4F), fontWeight: FontWeight.w700)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/lessons'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14213D), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(ta ? 'பாடங்கள் பட்டியலுக்குச் செல்' : 'Back to Lessons', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              if (!passed) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(ta ? 'மீண்டும் முயற்சிக்க' : 'Try Again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
