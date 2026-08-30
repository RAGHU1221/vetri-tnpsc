import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/lesson_service.dart';
import 'lesson_detail_screen.dart';

class LessonListScreen extends StatefulWidget {
  const LessonListScreen({super.key});
  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  Future<List<LessonSummary>>? _future;

  // ஒவ்வொரு lesson-க்கும் வித்தியாசமான வண்ணம் — படிக்க easy-ஆ, distinguish
  // பண்ண எளிதாக இருக்க rotate ஆகும் palette.
  static const _palette = [
    [Color(0xFFB33A2B), Color(0xFF8C2A1F)],
    [Color(0xFF3E6FB0), Color(0xFF2A4F82)],
    [Color(0xFF6B4FA0), Color(0xFF4E3878)],
    [Color(0xFF1B8A96), Color(0xFF13636C)],
    [Color(0xFFD97B29), Color(0xFFA85E1D)],
    [Color(0xFF2E7D4F), Color(0xFF1F5C38)],
    [Color(0xFFC9971C), Color(0xFFA87A12)],
  ];

  @override
  void initState() {
    super.initState();
    _future = LessonService.list();
  }

  Future<void> _refresh() async {
    setState(() => _future = LessonService.list());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final ta = context.watch<AppProvider>().isTamil;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EE),
      appBar: AppBar(
        title: Text(ta ? 'பாடங்கள்' : 'Lessons'),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _refresh),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<LessonSummary>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Text(ta ? 'பாடங்கள் load ஆகவில்லை. மீண்டும் முயற்சிக்கவும்.' : 'Could not load lessons. Pull to retry.',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              );
            }
            final lessons = snap.data!;
            final passedCount = lessons.where((l) => l.passed).length;
            return ListView(
              padding: const EdgeInsets.all(14),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // முன்னேற்றம் — எத்தனை lessons pass ஆயிற்று, தெளிவாக மேலே தெரியும்.
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF2E7D4F), Color(0xFF1F5C38)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ta ? '$passedCount / ${lessons.length} பாடங்கள் முடிந்தது'
                                     : '$passedCount / ${lessons.length} lessons completed',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15.5)),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: lessons.isEmpty ? 0 : passedCount / lessons.length,
                                minHeight: 7,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation(Color(0xFFF1ECDD)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                for (final l in lessons)
                  _LessonCard(
                    lesson: l,
                    ta: ta,
                    colors: _palette[l.lessonNo % _palette.length],
                    onTap: l.locked
                        ? () => _showLockedMessage(context, ta)
                        : () async {
                            // Navigator.push + MaterialPageRoute (not
                            // GoRouter's context.push) is deliberate here:
                            // it guarantees a brand-new widget/route/State
                            // every single call, no matter what internal
                            // page-caching GoRouter does for path-based
                            // navigation — this is what actually fixes the
                            // "tapping Lesson 2 shows Lesson 1" bug, since
                            // every earlier fix (ValueKey, didUpdateWidget)
                            // still went through GoRouter's own routing.
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LessonDetailScreen(lessonId: l.id),
                              ),
                            );
                            if (mounted) _refresh();
                          },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showLockedMessage(BuildContext context, bool ta) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ta
          ? '🔒 இந்த பாடம் இன்னும் திறக்கவில்லை — முந்தைய பாடத்தை pass பண்ணுங்க'
          : '🔒 This lesson is still locked — pass the previous lesson first'),
    ));
  }
}

class _LessonCard extends StatelessWidget {
  final LessonSummary lesson;
  final bool ta;
  final List<Color> colors;
  final VoidCallback onTap;
  const _LessonCard({required this.lesson, required this.ta, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locked = lesson.locked;
    final passed = lesson.passed;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 10, offset: const Offset(0, 3))],
        border: passed ? Border.all(color: const Color(0xFF2E7D4F), width: 1.5) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: locked
                        ? const LinearGradient(colors: [Color(0xFFBFBFBF), Color(0xFF8F8F8F)])
                        : LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  alignment: Alignment.center,
                  child: locked
                      ? const Icon(Icons.lock_rounded, color: Colors.white, size: 24)
                      : passed
                          ? const Icon(Icons.check_circle_rounded, color: Colors.white, size: 26)
                          : Text('${lesson.lessonNo}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ta ? 'பாடம் ${lesson.lessonNo}' : 'Lesson ${lesson.lessonNo}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                            color: locked ? Colors.grey.shade500 : colors[0]),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lesson.lessonTitleTa,
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15.5,
                            color: locked ? Colors.grey.shade500 : const Color(0xFF14213D)),
                      ),
                      if (passed && lesson.score != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          ta ? 'Score: ${lesson.score!.toStringAsFixed(0)}%' : 'Score: ${lesson.score!.toStringAsFixed(0)}%',
                          style: const TextStyle(color: Color(0xFF2E7D4F), fontWeight: FontWeight.w700, fontSize: 12.5),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(locked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
                    color: locked ? Colors.grey.shade400 : const Color(0xFF14213D)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
