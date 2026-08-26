import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/auth_service.dart';
import '../../services/stats_service.dart';
import '../../services/job_notification_service.dart';
import '../../services/question_service.dart';
import '../widgets/vetri_buttons.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _streak;
  int _openNotifCount = 0;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    StatsService.streakPing().then((d) {
      if (mounted && d != null) setState(() => _streak = d['current_streak']);
    });
    JobNotificationService.fetchAll().then((list) {
      if (mounted) setState(() => _openNotifCount = list.where((n) => n.status == 'open').length);
    });
  }

  /// Force-fetches the latest questions from the live server (bypassing
  /// whatever was cached in memory) and reports the real outcome — how
  /// many questions actually loaded, or the exact error if it fell back
  /// to offline data — right here on the dashboard. No need to hunt for
  /// a refresh icon on another screen to find out whether a sync worked.
  Future<void> _sync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    final ta = context.read<AppProvider>().isTamil;
    try {
      final questions = await QuestionService.refresh();
      if (!mounted) return;
      if (QuestionService.usedSeedFallback) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(seconds: 8),
          backgroundColor: const Color(0xFFB33A2B),
          content: Text(ta
              ? 'Sync தோல்வி — server-ஐ அடைய முடியல, பழைய offline data (${questions.length}) காட்டுது.\n${QuestionService.lastError ?? ''}'
              : 'Sync failed — could not reach the server, showing old offline data (${questions.length}).\n${QuestionService.lastError ?? ''}'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(seconds: 4),
          backgroundColor: const Color(0xFF2E7D4F),
          content: Text(ta
              ? 'Sync ஆச்சு — ${questions.length} கேள்விகள் load ஆச்சு ✓'
              : 'Synced — ${questions.length} questions loaded ✓'),
        ));
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final ta = app.isTamil;
    const guideKeyMap = {'G4': 'tnpsc_g4', 'G2A': 'tnpsc_g2a', 'NMMS': 'nmms', 'G1': 'tnpsc_g1'};
    final syllabusRoute = '/guide/${guideKeyMap[app.examGroup] ?? 'tnpsc_g4'}';
    final tiles = [
      (Icons.menu_book_rounded, ta ? 'பாடத்திட்டம்' : 'Syllabus', syllabusRoute,
          const [Color(0xFF3E6FB0), Color(0xFF2A4F82)]),
      (Icons.quiz_rounded, ta ? 'கேள்வி வங்கி' : 'Question Bank', '/syllabus',
          const [Color(0xFFC9971C), Color(0xFFA87A12)]),
      (Icons.timer_rounded, ta ? 'மாதிரி தேர்வு' : 'Mock Test', '/test-setup',
          const [Color(0xFFB33A2B), Color(0xFF8C2A1F)]),
      (Icons.newspaper_rounded, ta ? 'நடப்பு நிகழ்வுகள்' : 'Current Affairs',
          '/current-affairs', const [Color(0xFF6B4FA0), Color(0xFF4E3878)]),
      (Icons.smart_toy_rounded, ta ? 'AI ஆசிரியர்' : 'AI Tutor', '/ai-chat',
          const [Color(0xFF2E7D4F), Color(0xFF1F5C38)]),
      (Icons.emoji_events_rounded, ta ? 'முன்னேற்றம்' : 'Progress', '/progress',
          const [Color(0xFF14213D), Color(0xFF0D1830)]),
      (Icons.explore_rounded, ta ? 'வழிகாட்டி' : 'Guide', '/guide',
          const [Color(0xFF1B8A96), Color(0xFF13636C)]),
      (Icons.notifications_active_rounded, ta ? 'அறிவிப்புகள்' : 'Notifications', '/notifications',
          const [Color(0xFFD97B29), Color(0xFFA85E1D)]),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EE),
      appBar: AppBar(
        elevation: 0,
        title: Row(children: [
          Text(ta ? 'வெற்றி TNPSC' : 'Vetri TNPSC'),
          if (_streak != null && _streak! > 0)
            Container(
              margin: const EdgeInsets.only(left: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.22),
                  borderRadius: BorderRadius.circular(14)),
              child: Text('🔥$_streak',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ),
        ]),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              VetriIconButton(
                icon: Icons.sync_rounded,
                bg: const Color(0xFF1B8A96),
                size: 40,
                onTap: _syncing ? () {} : _sync,
              ),
              if (_syncing)
                const Positioned.fill(
                  child: Center(
                    child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              VetriIconButton(
                icon: Icons.notifications_rounded,
                bg: const Color(0xFFD97B29),
                size: 40,
                onTap: () => context.push('/notifications'),
              ),
              if (_openNotifCount > 0)
                Positioned(
                  right: -2, top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Color(0xFFB33A2B), shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('$_openNotifCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          VetriChip(
            label: ta ? 'EN' : 'த',
            selected: false,
            onTap: app.toggleLang,
          ),
          const SizedBox(width: 10),
          VetriIconButton(
            icon: Icons.logout_rounded,
            bg: const Color(0xFFB33A2B),
            size: 40,
            onTap: () async {
              await AuthService().logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  VetriChip(
                    label: ta ? '📗 குரூப் 4' : '📗 Group 4',
                    selected: app.examGroup == 'G4',
                    onTap: () => app.setExamGroup('G4'),
                  ),
                  const SizedBox(width: 8),
                  VetriChip(
                    label: ta ? '📘 குரூப் 2/2A' : '📘 Group 2/2A',
                    selected: app.examGroup == 'G2A',
                    onTap: () => app.setExamGroup('G2A'),
                  ),
                  const SizedBox(width: 8),
                  VetriChip(
                    label: ta ? '📙 NMMS (8th)' : '📙 NMMS (8th)',
                    selected: app.examGroup == 'NMMS',
                    onTap: () => app.setExamGroup('NMMS'),
                  ),
                  const SizedBox(width: 8),
                  VetriChip(
                    label: ta ? '🏅 குரூப் 1' : '🏅 Group 1',
                    selected: app.examGroup == 'G1',
                    onTap: () => app.setExamGroup('G1'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: .95,
              children: [
                for (final (icon, label, route, colors) in tiles)
                  _DashTile(icon: icon, label: label, colors: colors, onTap: () => context.push(route)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;
  const _DashTile({required this.icon, required this.label, required this.colors, required this.onTap});
  @override
  State<_DashTile> createState() => _DashTileState();
}

class _DashTileState extends State<_DashTile> {
  double _scale = 1;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = .95),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
                colors: widget.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [
              BoxShadow(
                  color: widget.colors.first.withOpacity(.38),
                  blurRadius: 16,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.18), shape: BoxShape.circle),
                child: Icon(widget.icon, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(widget.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
