import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/question_service.dart';
import '../widgets/vetri_buttons.dart';
import '../widgets/question_body.dart';

class QuestionListScreen extends StatelessWidget {
  final String subject;
  const QuestionListScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final ta = app.isTamil;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EE),
      appBar: AppBar(title: Text(ta ? 'கேள்விகள்' : 'Questions'), elevation: 0),
      body: FutureBuilder(
        future: QuestionService.bySubject(groupExam: app.examGroup),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final questions = snap.data![subject] ?? [];
          questions.sort((a, b) => b.repeatCount.compareTo(a.repeatCount));
          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: questions.length,
            itemBuilder: (context, i) => _QuestionCard(q: questions[i], ta: ta, index: i + 1),
          );
        },
      ),
    );
  }
}

class _QuestionCard extends StatefulWidget {
  final Question q;
  final bool ta;
  final int index;
  const _QuestionCard({required this.q, required this.ta, required this.index});

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final q = widget.q;
    final ta = widget.ta;
    final options = ta || q.optionsEn.isEmpty ? q.optionsTa : q.optionsEn;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26, height: 26,
                  decoration: const BoxDecoration(
                      color: Color(0xFFF1ECDD), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('${widget.index}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                ),
                const Spacer(),
                if (q.importanceBadge.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: q.repeatCount >= 3
                          ? [const Color(0xFFB33A2B), const Color(0xFF8C2A1F)]
                          : [const Color(0xFFC9971C), const Color(0xFFA87A12)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: (q.repeatCount >= 3 ? const Color(0xFFB33A2B) : const Color(0xFFC9971C))
                                .withOpacity(.35),
                            blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Text(
                      '${q.importanceBadge} ${ta ? "முக்கியம்" : "Important"} ${q.repeatCount}×',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            QuestionBody(q: q, ta: ta),
            const SizedBox(height: 12),
            for (int i = 0; i < options.length; i++)
              VetriOptionTile(
                letter: String.fromCharCode(65 + i),
                text: options[i],
                selected: _selected == i,
                isCorrect: _selected == null ? null : (i == q.correct),
                onTap: () => setState(() => _selected = i),
              ),
            if (_selected != null) ...[
              const SizedBox(height: 4),
              if (q.bookTa != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                      color: const Color(0xFFEEF3FB),
                      borderRadius: BorderRadius.circular(9)),
                  child: Text(
                      '📖 ${ta ? "மூலம்" : "Source"}: ${q.bookTa}'
                      '${q.pageNo != null ? " · ${ta ? "பக்கம்" : "Page"} ${q.pageNo}" : ""}',
                      style: const TextStyle(fontSize: 13)),
                ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E8),
                    borderRadius: BorderRadius.circular(9)),
                child: Text(
                    '💡 ${ta ? (q.explanationTa ?? "") : (q.explanationEn ?? q.explanationTa ?? "")}',
                    style: const TextStyle(fontSize: 13.5, height: 1.4)),
              ),
              if (q.yearsAsked.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 9),
                  child: Wrap(
                    spacing: 6,
                    children: [
                      for (final y in q.yearsAsked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                              color: const Color(0xFF14213D),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(y,
                              style: const TextStyle(
                                  fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
