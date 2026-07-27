import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/test_service.dart';
import '../widgets/vetri_buttons.dart';
import 'syllabus_screen.dart';

class TestSetupScreen extends StatefulWidget {
  const TestSetupScreen({super.key});
  @override
  State<TestSetupScreen> createState() => _TestSetupScreenState();
}

class _TestSetupScreenState extends State<TestSetupScreen> {
  String? _subject; // null = full mock
  int _count = 20;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final ta = app.isTamil;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EE),
      appBar: AppBar(title: Text(ta ? 'மாதிரி தேர்வு' : 'Mock Test'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(ta ? '📚 பாடம் தேர்வு' : '📚 Choose subject',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 9, runSpacing: 9,
            children: [
              VetriChip(
                label: ta ? 'அனைத்தும் (Full)' : 'All (Full)',
                icon: Icons.all_inclusive,
                selected: _subject == null,
                onTap: () => setState(() => _subject = null),
              ),
              for (final e in SyllabusScreen.names.entries)
                VetriChip(
                  label: ta ? e.value.$1 : e.value.$2,
                  selected: _subject == e.key,
                  onTap: () => setState(() => _subject = e.key),
                ),
            ],
          ),
          const SizedBox(height: 26),
          Text(ta ? '🔢 கேள்விகள் எண்ணிக்கை' : '🔢 Number of questions',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8, offset: const Offset(0, 3))
                ]),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF2E7D4F),
                    thumbColor: const Color(0xFF2E7D4F),
                    overlayColor: const Color(0xFF2E7D4F).withOpacity(.15),
                    inactiveTrackColor: const Color(0xFFEDE6D4),
                  ),
                  child: Slider(
                    value: _count.toDouble(), min: 10, max: 50, divisions: 4,
                    label: '$_count',
                    onChanged: (v) => setState(() => _count = v.round()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 14,
                    children: [
                      _statPill('❓', '$_count', ta ? 'கேள்விகள்' : 'questions'),
                      _statPill('⏱️', '${(_count * 0.9).round()}', ta ? 'நிமிடம்' : 'min'),
                      _statPill('🎯', '${(_count * 1.5).round()}', ta ? 'மதிப்பெண்' : 'marks'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          VetriButton(
            label: ta ? 'தேர்வு தொடங்கு' : 'Start Test',
            icon: Icons.play_arrow_rounded,
            style: VetriButtonStyle.danger,
            onPressed: () {
              final cfg = TestConfig(
                type: _subject == null ? 'full' : 'mini',
                subject: _subject,
                groupExam: app.examGroup,
                count: _count,
                duration: Duration(seconds: (_count * 54)),
              );
              context.push('/test', extra: cfg);
            },
          ),
        ],
      ),
    );
  }

  Widget _statPill(String emoji, String value, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text('$value $label',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      );
}
