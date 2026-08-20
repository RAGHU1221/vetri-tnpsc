import 'package:flutter/material.dart';
import '../../services/question_service.dart';

const _ink = Color(0xFF14213D);
const _gold = Color(0xFFC9971C);
const _leaf = Color(0xFF2E7D4F);

/// Renders a question's body EXACTLY matching the real TNPSC paper pattern:
/// - simple: plain bilingual question text
/// - match_table: "List I / List II" two-column table (அ/ஆ/இ/ஈ ↔ 1/2/3/4)
/// - assertion_reason: கூற்று [A] + காரணம் [R] blocks
/// Also shows question image (if any) and a "PYQ verified" badge.
class QuestionBody extends StatelessWidget {
  final Question q;
  final bool ta;
  const QuestionBody({super.key, required this.q, required this.ta});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (q.sourceVerified)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3E6FB0), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.verified, size: 14, color: Color(0xFF3E6FB0)),
                SizedBox(width: 4),
                Text('உண்மையான வினாத்தாள் · Real PYQ',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF3E6FB0))),
              ],
            ),
          ),

        // Question image (diagram/map) if present
        if (q.imageUrl != null && q.imageUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                q.imageUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (c, child, progress) => progress == null
                    ? child
                    : const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                errorBuilder: (c, e, s) => Container(
                  padding: const EdgeInsets.all(14),
                  color: const Color(0xFFF1ECDD),
                  child: Text(ta ? '🖼️ படம் ஏற்ற முடியவில்லை' : '🖼️ Image failed to load'),
                ),
              ),
            ),
          ),

        // Question text (always shown as intro line)
        Text(q.questionTa,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.5)),
        if (q.questionEn.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(q.questionEn,
                style: TextStyle(
                    fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey.shade700)),
          ),

        const SizedBox(height: 10),

        if (q.format == 'match_table') _matchTable(),
        if (q.format == 'assertion_reason') _assertionReason(),
      ],
    );
  }

  Widget _matchTable() {
    final list1 = ta ? (q.tableList1Ta ?? []) : (q.tableList1En ?? q.tableList1Ta ?? []);
    final list2 = ta ? (q.tableList2Ta ?? []) : (q.tableList2En ?? q.tableList2Ta ?? []);
    if (list1.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0DACB)),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        border: TableBorder.symmetric(
            inside: const BorderSide(color: Color(0xFFE0DACB))),
        columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
        children: [
          TableRow(
            decoration: const BoxDecoration(color: _ink),
            children: [
              _cell(ta ? 'பட்டியல் I' : 'List I', header: true),
              _cell(ta ? 'பட்டியல் II' : 'List II', header: true),
            ],
          ),
          for (int i = 0; i < list1.length; i++)
            TableRow(children: [
              _cell(list1[i]),
              _cell(i < list2.length ? list2[i] : ''),
            ]),
        ],
      ),
    );
  }

  Widget _cell(String text, {bool header = false}) => Padding(
        padding: const EdgeInsets.all(10),
        child: Text(text,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: header ? FontWeight.w800 : FontWeight.w500,
                color: header ? Colors.white : _ink)),
      );

  Widget _assertionReason() {
    final assertion = ta ? q.assertionTa : (q.assertionEn ?? q.assertionTa);
    final reason = ta ? q.reasonTa : (q.reasonEn ?? q.reasonTa);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statementBlock(ta ? 'கூற்று [A]' : 'Assertion [A]', assertion ?? ''),
        const SizedBox(height: 8),
        _statementBlock(ta ? 'காரணம் [R]' : 'Reason [R]', reason ?? ''),
      ],
    );
  }

  Widget _statementBlock(String label, String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF5),
          borderRadius: BorderRadius.circular(9),
          border: Border(left: BorderSide(color: _gold, width: 4)),
        ),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: _ink, height: 1.5),
            children: [
              TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: _leaf)),
              TextSpan(text: text),
            ],
          ),
        ),
      );
}
