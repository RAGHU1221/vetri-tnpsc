import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/question_service.dart';
import '../../services/test_service.dart';
import '../widgets/vetri_buttons.dart';
import '../widgets/question_body.dart';

class TestScreen extends StatefulWidget {
  final TestConfig config;
  const TestScreen({super.key, required this.config});
  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  List<Question>? _questions;
  final Map<int, int> _answers = {};
  int _current = 0;
  late Duration _remaining;
  Timer? _timer;
  final _startedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _remaining = widget.config.duration;
    TestService.buildTest(widget.config).then((qs) {
      if (!mounted) return;
      setState(() => _questions = qs);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remaining.inSeconds <= 1) {
          _submit(auto: true); // ⏰ auto-submit
        } else {
          setState(() => _remaining -= const Duration(seconds: 1));
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _submit({bool auto = false}) async {
    _timer?.cancel();
    final result = await TestService.evaluate(widget.config, _questions!,
        _answers, DateTime.now().difference(_startedAt));
    if (!mounted) return;
    context.pushReplacement('/test-result',
        extra: (result, _questions!, _answers, auto));
  }

  String get _clock {
    final m = _remaining.inMinutes.toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final ta = context.watch<AppProvider>().isTamil;
    if (_questions == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final q = _questions![_current];
    final options = ta || q.optionsEn.isEmpty ? q.optionsTa : q.optionsEn;
    final lowTime = _remaining.inMinutes < 2;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF7EE),
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text('${_current + 1} / ${_questions!.length}'),
          actions: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
              decoration: BoxDecoration(
                color: lowTime ? const Color(0xFFB33A2B) : Colors.white24,
                borderRadius: BorderRadius.circular(18),
                boxShadow: lowTime
                    ? [BoxShadow(color: const Color(0xFFB33A2B).withOpacity(.5), blurRadius: 10)]
                    : [],
              ),
              child: Row(children: [
                const Icon(Icons.timer_outlined, size: 16, color: Colors.white),
                const SizedBox(width: 5),
                Text(_clock, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ]),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Column(
          children: [
            // OMR palette
            Container(
              height: 56,
              color: Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                itemCount: _questions!.length,
                itemBuilder: (c, i) {
                  final isCur = i == _current;
                  final isAns = _answers.containsKey(i);
                  return GestureDetector(
                    onTap: () => setState(() => _current = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 38,
                      margin: const EdgeInsets.symmetric(horizontal: 3.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isCur
                            ? const LinearGradient(colors: [Color(0xFF14213D), Color(0xFF0D1830)])
                            : isAns
                                ? const LinearGradient(colors: [Color(0xFF2E7D4F), Color(0xFF1F5C38)])
                                : null,
                        color: isCur || isAns ? null : const Color(0xFFF1ECDD),
                        boxShadow: isCur
                            ? [BoxShadow(color: const Color(0xFF14213D).withOpacity(.4), blurRadius: 8)]
                            : [],
                      ),
                      child: Center(
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: isCur || isAns ? Colors.white : const Color(0xFF14213D)))),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  QuestionBody(q: q, ta: ta),
                  const SizedBox(height: 16),
                  for (int i = 0; i < options.length; i++)
                    VetriOptionTile(
                      letter: String.fromCharCode(65 + i),
                      text: options[i],
                      selected: _answers[_current] == i,
                      onTap: () => setState(() =>
                          _answers[_current] == i
                              ? _answers.remove(_current)
                              : _answers[_current] = i),
                    ),
                ],
              ),
            ),
            SafeArea(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: VetriButton(
                        label: ta ? '← முந்தைய' : '← Prev',
                        style: VetriButtonStyle.outline,
                        height: 50,
                        onPressed: _current > 0 ? () => setState(() => _current--) : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _current < _questions!.length - 1
                          ? VetriButton(
                              label: ta ? 'அடுத்தது →' : 'Next →',
                              height: 50,
                              onPressed: () => setState(() => _current++),
                            )
                          : VetriButton(
                              label: ta ? 'முடி ✓' : 'Finish ✓',
                              style: VetriButtonStyle.danger,
                              height: 50,
                              onPressed: () => showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  title: Text(ta ? 'தேர்வு முடிக்கவா?' : 'Submit test?'),
                                  content: Text(
                                      '${_answers.length}/${_questions!.length} ${ta ? "பதிலளித்தீர்கள்" : "answered"}'),
                                  actions: [
                                    TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text(ta ? 'இல்லை' : 'No')),
                                    FilledButton(
                                        style: FilledButton.styleFrom(
                                            backgroundColor: const Color(0xFF2E7D4F)),
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _submit();
                                        },
                                        child: Text(ta ? 'சமர்ப்பி' : 'Submit')),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
