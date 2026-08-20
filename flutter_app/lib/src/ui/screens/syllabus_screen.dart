import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/question_service.dart';

class SyllabusScreen extends StatelessWidget {
  const SyllabusScreen({super.key});

  static const names = {
    'tamil': ('பொதுத் தமிழ்', 'General Tamil'),
    'history': ('வரலாறு', 'History'),
    'polity': ('இந்திய அரசியல்', 'Indian Polity'),
    'geography': ('புவியியல்', 'Geography'),
    'economy': ('பொருளாதாரம்', 'Economy'),
    'science': ('பொது அறிவியல்', 'General Science'),
    'current_affairs': ('நடப்பு நிகழ்வுகள்', 'Current Affairs'),
    'aptitude': ('திறனறிவு', 'Aptitude'),
  };

  static const _icons = {
    'tamil': Icons.translate_rounded,
    'history': Icons.account_balance_rounded,
    'polity': Icons.gavel_rounded,
    'geography': Icons.public_rounded,
    'economy': Icons.currency_rupee_rounded,
    'science': Icons.science_rounded,
    'current_affairs': Icons.newspaper_rounded,
    'aptitude': Icons.calculate_rounded,
  };

  static const _colors = {
    'tamil': [Color(0xFFB33A2B), Color(0xFF8C2A1F)],
    'history': [Color(0xFFC9971C), Color(0xFFA87A12)],
    'polity': [Color(0xFF3E6FB0), Color(0xFF2A4F82)],
    'geography': [Color(0xFF2E7D4F), Color(0xFF1F5C38)],
    'economy': [Color(0xFF6B4FA0), Color(0xFF4E3878)],
    'science': [Color(0xFF1B8A96), Color(0xFF13636C)],
    'current_affairs': [Color(0xFFD97B29), Color(0xFFA85E1D)],
    'aptitude': [Color(0xFF14213D), Color(0xFF0D1830)],
  };

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final ta = app.isTamil;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EE),
      appBar: AppBar(
          title: Text(ta
              ? 'பாடத்திட்டம் · ${app.examGroupLabelTa}'
              : 'Syllabus · ${app.examGroupLabelEn}'),
          elevation: 0),
      body: FutureBuilder(
        future: QuestionService.bySubject(groupExam: app.examGroup),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final subjects = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              for (final entry in subjects.entries)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 9, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () => context.push('/questions/${entry.key}'),
                      child: Padding(
                        padding: const EdgeInsets.all(13),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(13),
                                gradient: LinearGradient(
                                    colors: _colors[entry.key] ?? const [Color(0xFF2E7D4F), Color(0xFF1F5C38)],
                                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                              ),
                              child: Icon(_icons[entry.key] ?? Icons.folder_open,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      ta
                                          ? (names[entry.key]?.$1 ?? entry.key)
                                          : (names[entry.key]?.$2 ?? entry.key),
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                                  const SizedBox(height: 3),
                                  Text(ta
                                      ? '${entry.value.length} கேள்விகள்'
                                      : '${entry.value.length} questions',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFF1ECDD), shape: BoxShape.circle),
                              child: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF14213D)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
