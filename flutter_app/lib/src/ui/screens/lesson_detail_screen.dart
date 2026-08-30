import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/lesson_service.dart';

/// The source workbook bakes a couple of administrative/scope notes into
/// many lessons' explanation text (sourcing disclaimers, class-range scope
/// notes) — useful for whoever prepared the material, not for a student
/// reading the lesson. Stripped here at display time only; the stored
/// explanation_ta itself is left untouched (requirement: don't modify
/// source content — this only affects what's rendered on screen).
String _cleanExplanation(String raw) {
  final paragraphs = raw.split(RegExp(r'\n\s*\n'));
  final kept = paragraphs.where((p) {
    final t = p.trim();
    if (t.isEmpty) return false;
    if (t.startsWith('குறிப்பு:')) return false; // sourcing/attribution disclaimer
    if (t.startsWith('இந்தப் பகுதியில்') || t.startsWith('இந்த பகுதியில்')) return false; // class-range scope note
    return true;
  });
  return kept.join('\n\n').trim();
}

class LessonDetailScreen extends StatefulWidget {
  final int lessonId;
  const LessonDetailScreen({super.key, required this.lessonId});
  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  Future<LessonDetail>? _future;

  @override
  void initState() {
    super.initState();
    _future = LessonService.detail(widget.lessonId);
  }

  @override
  Widget build(BuildContext context) {
    final ta = context.watch<AppProvider>().isTamil;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EE),
      body: FutureBuilder<LessonDetail>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
                    const SizedBox(height: 20),
                    Text(ta ? '🔒 இந்த பாடம் இன்னும் திறக்கவில்லை' : '🔒 This lesson is still locked',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final l = snap.data!;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 130,
                backgroundColor: const Color(0xFF3E6FB0),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 14, right: 16),
                  title: Text(l.lessonTitleTa,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3E6FB0), Color(0xFF2A4F82)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 44),
                        child: Text(ta ? 'பாடம் ${l.lessonNo}' : 'Lesson ${l.lessonNo}',
                            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (l.explanationTa != null && l.explanationTa!.isNotEmpty)
                      _SectionCard(
                        icon: Icons.menu_book_rounded,
                        color: const Color(0xFF3E6FB0),
                        title: ta ? 'விளக்கம்' : 'Explanation',
                        child: Text(_cleanExplanation(l.explanationTa!),
                            style: const TextStyle(fontSize: 15.5, height: 1.65, color: Color(0xFF14213D))),
                      ),
                    if (l.importantPointsList.isNotEmpty)
                      _SectionCard(
                        icon: Icons.star_rounded,
                        color: const Color(0xFFD97B29),
                        title: ta ? 'முக்கிய குறிப்புகள்' : 'Important Points',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: l.importantPointsList
                              .map((p) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Icon(Icons.circle, size: 7, color: Color(0xFFD97B29)),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(p.replaceFirst(RegExp(r'^⭐?\s*(முக்கியமாக படிக்க:)?\s*'), ''),
                                              style: const TextStyle(fontSize: 14.5, height: 1.5, color: Color(0xFF14213D))),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    if (l.sampleQuestionTa != null && l.sampleQuestionTa!.isNotEmpty)
                      _SectionCard(
                        icon: Icons.lightbulb_rounded,
                        color: const Color(0xFF6B4FA0),
                        title: ta ? 'மாதிரி வினா' : 'Sample Question',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.sampleQuestionTa!,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, height: 1.5)),
                            if (l.sampleOptions != null) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8, runSpacing: 8,
                                children: l.sampleOptions!.map((o) {
                                  final isAns = o.trim() == (l.sampleCorrectAnswerTa ?? '').trim();
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: isAns ? const Color(0xFFE8F5EC) : const Color(0xFFF1ECDD),
                                      borderRadius: BorderRadius.circular(20),
                                      border: isAns ? Border.all(color: const Color(0xFF2E7D4F)) : null,
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      if (isAns) const Padding(
                                        padding: EdgeInsets.only(right: 5),
                                        child: Icon(Icons.check_circle, size: 15, color: Color(0xFF2E7D4F)),
                                      ),
                                      Text(o, style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: isAns ? FontWeight.w800 : FontWeight.w500,
                                          color: isAns ? const Color(0xFF2E7D4F) : const Color(0xFF14213D))),
                                    ]),
                                  );
                                }).toList(),
                              ),
                            ],
                            if (l.sampleQuestionExplanationTa != null && l.sampleQuestionExplanationTa!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: const Color(0xFFF7F5FF), borderRadius: BorderRadius.circular(10)),
                                child: Text(l.sampleQuestionExplanationTa!,
                                    style: TextStyle(fontSize: 13, height: 1.5, color: Colors.grey.shade700)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: l.tests.isEmpty ? null : () => context.push('/lessons/${l.id}/test', extra: l),
                        icon: const Icon(Icons.quiz_rounded),
                        label: Text(ta ? 'பாடம் சோதனை தொடங்கு (${l.tests.length} வினாக்கள்)' : 'Start Lesson Test (${l.tests.length} Qs)',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D4F), foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        ta ? 'பாஸ் ஆக ${l.passPercent}% தேவை' : 'Need ${l.passPercent}% to pass',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Widget child;
  const _SectionCard({required this.icon, required this.color, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8, offset: const Offset(0, 3))],
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
