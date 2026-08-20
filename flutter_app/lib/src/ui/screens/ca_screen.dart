import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/ca_service.dart';
import '../../services/test_service.dart';
import '../widgets/vetri_buttons.dart';

class CAScreen extends StatefulWidget {
  const CAScreen({super.key});
  @override
  State<CAScreen> createState() => _CAScreenState();
}

class _CAScreenState extends State<CAScreen> {
  bool _tnOnly = false;
  late Future<List<CAItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = CAService.fetch();
  }

  void _reload() =>
      setState(() => _future = CAService.fetch(tnOnly: _tnOnly));

  static const catIcons = {
    'tn': '🏛️', 'national': '🇮🇳', 'international': '🌍',
    'science': '🔬', 'sports': '🏆', 'awards': '🎖️',
    'schemes': '📋', 'general': '📰',
  };

  static const catColors = {
    'tn': Color(0xFFC9971C), 'national': Color(0xFF1E6F46), 'international': Color(0xFF2563EB),
    'science': Color(0xFF7C3AED), 'sports': Color(0xFFDC2626), 'awards': Color(0xFFB45309),
    'schemes': Color(0xFF0F766E), 'general': Color(0xFF334155),
  };

  static const catLabelsTa = {
    'tn': 'தமிழ்நாடு', 'national': 'தேசியம்', 'international': 'சர்வதேசம்',
    'science': 'அறிவியல்', 'sports': 'விளையாட்டு', 'awards': 'விருதுகள்',
    'schemes': 'திட்டங்கள்', 'general': 'பொது',
  };

  static const catLabelsEn = {
    'tn': 'Tamil Nadu', 'national': 'National', 'international': 'International',
    'science': 'Science', 'sports': 'Sports', 'awards': 'Awards',
    'schemes': 'Schemes', 'general': 'General',
  };

  @override
  Widget build(BuildContext context) {
    final ta = context.watch<AppProvider>().isTamil;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3EA),
      appBar: AppBar(title: Text(ta ? 'நடப்பு நிகழ்வுகள்' : 'Current Affairs'), elevation: 0),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(colors: [Color(0xFFC9971C), Color(0xFFA87A12)]),
          boxShadow: [BoxShadow(color: const Color(0xFFC9971C).withOpacity(.45), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.bolt, color: Color(0xFF14213D)),
          label: Text(ta ? 'Daily Quiz' : 'Daily Quiz',
              style: const TextStyle(color: Color(0xFF14213D), fontWeight: FontWeight.w800)),
          onPressed: () => context.push('/test',
              extra: TestConfig(
                  type: 'daily', count: 10,
                  groupExam: context.read<AppProvider>().examGroup,
                  duration: const Duration(minutes: 9))),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                VetriChip(
                  label: ta ? '🏛️ தமிழ்நாடு மட்டும்' : '🏛️ TN only',
                  selected: _tnOnly,
                  onTap: () {
                    _tnOnly = !_tnOnly;
                    _reload();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return Center(
                      child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                        ta
                            ? 'இன்னும் செய்திகள் இல்லை.\nAdmin panel-la daily update pannunga!'
                            : 'No items yet.\nAdd daily updates from the admin panel!',
                        textAlign: TextAlign.center),
                  ));
                }
                // Group by date
                final byDate = <String, List<CAItem>>{};
                for (final it in items) {
                  byDate.putIfAbsent(it.date, () => []).add(it);
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                  children: [
                    for (final e in byDate.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF14213D),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('📅 ${e.key}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                      for (final it in e.value)
                        _NewsCard(
                          item: it,
                          ta: ta,
                          icon: catIcons[it.category] ?? '📰',
                          color: catColors[it.category] ?? const Color(0xFF334155),
                          categoryLabel: ta
                              ? (catLabelsTa[it.category] ?? it.category)
                              : (catLabelsEn[it.category] ?? it.category),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatefulWidget {
  final CAItem item;
  final bool ta;
  final String icon;
  final Color color;
  final String categoryLabel;
  const _NewsCard({
    required this.item,
    required this.ta,
    required this.icon,
    required this.color,
    required this.categoryLabel,
  });

  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final title = widget.ta || it.titleEn.isEmpty ? it.titleTa : it.titleEn;
    final content = widget.ta ? it.contentTa : it.contentEn;
    final hasContent = content.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: it.isTn
            ? Border.all(color: const Color(0xFFC9971C), width: 1.4)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: hasContent ? () => setState(() => _expanded = !_expanded) : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.icon, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Text(widget.categoryLabel,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: widget.color)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (it.isTn)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFC9971C), Color(0xFFA87A12)]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.trending_up, size: 13, color: Colors.white),
                            SizedBox(width: 3),
                            Text('TN',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: _expanded ? null : 3,
                  overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                      height: 1.35,
                      color: Color(0xFF14213D)),
                ),
                if (_expanded && hasContent) ...[
                  const SizedBox(height: 10),
                  Container(height: 1, color: const Color(0xFFEFEAE0)),
                  const SizedBox(height: 10),
                  Text(
                    content,
                    style: const TextStyle(
                        fontSize: 13.5, height: 1.5, color: Color(0xFF4B5563)),
                  ),
                ],
                if (hasContent) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _expanded
                            ? (widget.ta ? 'குறைவாகக் காட்டு' : 'Show less')
                            : (widget.ta ? 'மேலும் படிக்க' : 'Read more'),
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: widget.color),
                      ),
                      Icon(
                        _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 18,
                        color: widget.color,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
