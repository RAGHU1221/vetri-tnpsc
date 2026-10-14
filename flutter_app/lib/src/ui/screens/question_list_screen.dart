import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/question_service.dart';
import '../widgets/vetri_buttons.dart';
import '../widgets/question_body.dart';
import 'syllabus_screen.dart';

class QuestionListScreen extends StatefulWidget {
  final String subject;
  final String? unit; // preselected unit (from the Syllabus tree)
  const QuestionListScreen({super.key, required this.subject, this.unit});
  @override
  State<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> {
  Future<List<Question>>? _future;
  String? _group;
  String? _unit;          // null = all units
  bool _init = false;
  bool _importantOnly = false;

  Future<void> _reload() async {
    await QuestionService.refresh();
    if (!mounted) return;
    setState(() => _future = QuestionService.forSubject(widget.subject, groupExam: _group));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final ta = app.isTamil;
    if (_future == null || _group != app.examGroup) {
      _group = app.examGroup;
      if (!_init) { _unit = (widget.unit == null || widget.unit!.isEmpty) ? null : widget.unit; _init = true; } else { _unit = null; }
      _future = QuestionService.forSubject(widget.subject, groupExam: _group);
    }
    final n = SyllabusScreen.names[widget.subject.trim().toLowerCase()];
    final title = n == null ? (ta ? 'கேள்விகள்' : 'Questions') : (ta ? n.$1 : n.$2);
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EE),
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: ta ? 'முக்கியமானவை மட்டும்' : 'Important only',
            icon: Icon(_importantOnly ? Icons.star_rounded : Icons.star_border_rounded),
            onPressed: () => setState(() => _importantOnly = !_importantOnly),
          ),
          IconButton(
            tooltip: ta ? 'புதுப்பி' : 'Reload',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<List<Question>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data ?? [];
          final units = <String>{
            for (final q in all) if (q.unit.trim().isNotEmpty) q.unit.trim()
          }.toList()..sort();
          var questions = all.where((q) =>
              (_unit == null || q.unit.trim() == _unit) &&
              (!_importantOnly || q.repeatCount >= 2)).toList()
            ..sort((a, b) => b.repeatCount.compareTo(a.repeatCount));
          return Column(
            children: [
              if (units.length > 1)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(ta ? 'அனைத்தும் (${all.length})' : 'All (${all.length})'),
                          selected: _unit == null,
                          onSelected: (_) => setState(() => _unit = null),
                        ),
                      ),
                      for (final u in units)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('$u (${all.where((q) => q.unit.trim() == u).length})'),
                            selected: _unit == u,
                            onSelected: (_) => setState(() => _unit = u),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  child: questions.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 120),
                          Center(child: Text(ta ? 'கேள்விகள் இல்லை' : 'No questions found')),
                        ])
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(14),
                          itemCount: questions.length,
                          // key by id so option selection state never jumps between cards
                          itemBuilder: (context, i) => _QuestionCard(
                              key: ValueKey(questions[i].id),
                              q: questions[i], ta: ta, index: i + 1),
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

class _QuestionCard extends StatefulWidget {
  final Question q;
  final bool ta;
  final int index;
  const _QuestionCard({super.key, required this.q, required this.ta, required this.index});

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final q = widget.q;
    final ta = widget.ta;
    final options = q.optionsFor(ta);
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
