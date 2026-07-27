import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/stats_service.dart';
import 'syllabus_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  // G4 exam date — update as needed
  static final examDate = DateTime(2026, 12, 20);

  @override
  Widget build(BuildContext context) {
    final ta = context.watch<AppProvider>().isTamil;
    final daysLeft = examDate.difference(DateTime.now()).inDays;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EE),
      appBar: AppBar(
        elevation: 0,
        title: Text(ta ? 'முன்னேற்றம்' : 'Progress'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: const Color(0xFFC9971C),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
          tabs: [
            Tab(text: ta ? '📊 என் நிலை' : '📊 My Stats'),
            Tab(text: ta ? '🏆 தரவரிசை' : '🏆 Leaderboard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_myStats(ta, daysLeft), _leaderboard(ta)],
      ),
    );
  }

  Widget _myStats(bool ta, int daysLeft) {
    return FutureBuilder(
      future: StatsService.progress(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final d = snap.data;
        final overall = d?['overall'] ?? {};
        final streak = d?['streak'] ?? {};
        final subjects = (d?['by_subject'] as List?) ?? [];
        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            // ⏳ Exam countdown
            Card(
              color: const Color(0xFF14213D),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ta ? 'Group 4 தேர்வு' : 'Group 4 Exam',
                            style: const TextStyle(color: Colors.white70)),
                        const Text('20 Dec 2026',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 17)),
                      ],
                    ),
                    Column(
                      children: [
                        Text('$daysLeft',
                            style: const TextStyle(
                                color: Color(0xFFC9971C),
                                fontSize: 32,
                                fontWeight: FontWeight.w800)),
                        Text(ta ? 'நாட்கள் மீதம்' : 'days left',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // 🔥 Streak
            Row(
              children: [
                _big('🔥', '${streak['current_streak'] ?? 0}',
                    ta ? 'தற்போதைய streak' : 'Current streak'),
                _big('🏅', '${streak['longest_streak'] ?? 0}',
                    ta ? 'சிறந்த streak' : 'Best streak'),
              ],
            ),
            Row(
              children: [
                _big('📝', '${overall['tests'] ?? 0}',
                    ta ? 'தேர்வுகள்' : 'Tests taken'),
                _big('🎯', '${overall['avg_accuracy'] ?? 0}%',
                    ta ? 'சராசரி துல்லியம்' : 'Avg accuracy'),
              ],
            ),
            const SizedBox(height: 14),
            if (subjects.isNotEmpty) ...[
              Text(ta ? '📚 பாடம்-வாரியான துல்லியம்' : '📚 Subject-wise accuracy',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 8),
              for (final s in subjects) _subjectBar(s, ta),
              const SizedBox(height: 6),
              Text(
                  ta
                      ? '💡 குறைந்த % உள்ள பாடங்களில் கவனம் செலுத்துங்கள்!'
                      : '💡 Focus on your lowest % subjects!',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            ] else
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                    ta
                        ? 'இன்னும் தேர்வு எழுதவில்லை — முதல் mock test-ஐ எழுதுங்கள்! 💪'
                        : 'No tests yet — take your first mock test! 💪',
                    textAlign: TextAlign.center),
              ),
          ],
        );
      },
    );
  }

  Widget _big(String emoji, String value, String label) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(fontSize: 11.5),
                  textAlign: TextAlign.center),
            ]),
          ),
        ),
      );

  Widget _subjectBar(Map s, bool ta) {
    final acc = (s['accuracy'] as num?)?.toDouble() ?? 0;
    final name = ta
        ? (SyllabusScreen.names[s['subject']]?.$1 ?? s['subject'])
        : (SyllabusScreen.names[s['subject']]?.$2 ?? s['subject']);
    final color = acc >= 70
        ? const Color(0xFF2E7D4F)
        : acc >= 45
            ? const Color(0xFFC9971C)
            : const Color(0xFFB33A2B);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$name', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${acc.toStringAsFixed(1)}%',
                  style: TextStyle(fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
                value: acc / 100,
                minHeight: 9,
                backgroundColor: const Color(0xFFEDE6D4),
                color: color),
          ),
        ],
      ),
    );
  }

  Widget _leaderboard(bool ta) {
    return FutureBuilder(
      future: StatsService.leaderboard(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = (snap.data?['leaderboard'] as List?) ?? [];
        final myRank = snap.data?['my_rank'];
        if (rows.isEmpty) {
          return Center(
              child: Text(ta
                  ? 'இந்த வாரம் இன்னும் தேர்வுகள் இல்லை!'
                  : 'No tests this week yet!'));
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (myRank != null)
              Card(
                color: const Color(0xFFFFF6DC),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                      ta
                          ? '🎖️ இந்த வாரம் உங்கள் தரவரிசை: #$myRank'
                          : '🎖️ Your rank this week: #$myRank',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            for (final r in rows)
              Card(
                color: r['is_me'] == true ? const Color(0xFFEDF7F0) : null,
                child: ListTile(
                  leading: Text(
                      r['rank'] == 1
                          ? '🥇'
                          : r['rank'] == 2
                              ? '🥈'
                              : r['rank'] == 3
                                  ? '🥉'
                                  : '#${r['rank']}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  title: Text('${r['name']}${r['is_me'] == true ? " (${ta ? "நீங்கள்" : "You"})" : ""}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${r['tests']} ${ta ? "தேர்வுகள்" : "tests"} · ${r['accuracy']}%'),
                  trailing: Text('${r['total_score']}',
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E7D4F))),
                ),
              ),
          ],
        );
      },
    );
  }
}
