import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/ca_service.dart';
import '../../services/test_service.dart';
import '../widgets/vetri_buttons.dart';

// Luxury skeuomorphic palette — parchment, ink, aged gold, deep leaf.
const _paper = Color(0xFFFBF7EE);
const _parchment = Color(0xFFFFFDF8);
const _ink = Color(0xFF14213D);
const _gold = Color(0xFFC9971C);
const _goldDeep = Color(0xFF8C6B10);
const _leaf = Color(0xFF2E7D4F);
const _verm = Color(0xFFB33A2B);

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

  void _openDetail(BuildContext context, CAItem it, bool ta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CADetailSheet(item: it, isTamil: ta, catIcons: catIcons),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ta = context.watch<AppProvider>().isTamil;
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        title: Text(ta ? 'நடப்பு நிகழ்வுகள்' : 'Current Affairs'),
        elevation: 0,
        backgroundColor: _leaf,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF2E7D4F), Color(0xFF1F5C38)],
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(colors: [Color(0xFFDDB53A), _gold, _goldDeep],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(color: _gold.withOpacity(.5), blurRadius: 16, offset: const Offset(0, 6)),
            BoxShadow(color: Colors.white.withOpacity(.6), blurRadius: 2, offset: const Offset(0, -1)),
          ],
          border: Border.all(color: Colors.white.withOpacity(.35), width: 1),
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.bolt, color: _ink),
          label: const Text('Daily Quiz',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w800)),
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
                  return const Center(child: CircularProgressIndicator(color: _leaf));
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                          ta
                              ? 'இன்னும் செய்திகள் இல்லை.\nAdmin panel-la daily update pannunga!'
                              : 'No news yet.\nUpdate daily via admin panel!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  );
                }

                // Group by date, flatten for lazy ListView.builder — smooth
                // scrolling even with 170+ entries.
                final byDate = <String, List<CAItem>>{};
                for (final it in items) {
                  byDate.putIfAbsent(it.date, () => []).add(it);
                }
                final flat = <Object>[];
                for (final e in byDate.entries) {
                  flat.add(e.key);
                  flat.addAll(e.value);
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
                  itemCount: flat.length,
                  itemBuilder: (context, i) {
                    final entry = flat[i];
                    if (entry is String) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 10, left: 4),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [_ink, Color(0xFF1D2E52)]),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: _ink.withOpacity(.3), blurRadius: 6, offset: const Offset(0, 3))],
                            ),
                            child: Text('📅 $entry',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white, fontSize: 12.5)),
                          ),
                          const Expanded(child: Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Divider(color: Color(0xFFDCD3B8), thickness: 1),
                          )),
                        ]),
                      );
                    }
                    final it = entry as CAItem;
                    return _CACard(
                      item: it, isTamil: ta, catIcons: catIcons,
                      onTap: () => _openDetail(context, it, ta),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeuomorphic "index card" — layered shadows (raised paper look), an
/// embossed circular icon badge, and a gold foil-stamped ribbon corner for
/// TN-flagged items (like a wax seal on an official notice).
class _CACard extends StatefulWidget {
  final CAItem item;
  final bool isTamil;
  final Map<String, String> catIcons;
  final VoidCallback onTap;
  const _CACard({required this.item, required this.isTamil, required this.catIcons, required this.onTap});

  @override
  State<_CACard> createState() => _CACardState();
}

class _CACardState extends State<_CACard> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final ta = widget.isTamil;
    final title = ta || it.titleEn.isEmpty ? it.titleTa : it.titleEn;
    final body = ta ? it.contentTa : it.contentEn;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = .98),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 90),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_parchment, const Color(0xFFF6F0DF)],
            ),
            border: Border.all(
                color: it.isTn ? _gold : const Color(0xFFE6DFC8), width: it.isTn ? 1.6 : 1),
            boxShadow: [
              // Raised paper: soft ambient shadow below + subtle top highlight
              BoxShadow(color: Colors.black.withOpacity(.10), blurRadius: 10, offset: const Offset(0, 5)),
              BoxShadow(color: Colors.white.withOpacity(.9), blurRadius: 1, offset: const Offset(0, -1)),
              if (it.isTn)
                BoxShadow(color: _gold.withOpacity(.28), blurRadius: 14, spreadRadius: -2),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Embossed circular icon badge
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [Color(0xFFFFFFFF), Color(0xFFEFE7D2)]),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 4, offset: const Offset(0, 2)),
                          BoxShadow(color: Colors.white.withOpacity(.8), blurRadius: 2, offset: const Offset(-1, -1)),
                        ],
                        border: Border.all(color: const Color(0xFFE6DFC8), width: 1),
                      ),
                      alignment: Alignment.center,
                      child: Text(widget.catIcons[it.category] ?? '📰', style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _ink, height: 1.3)),
                          if (body.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(body,
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5, height: 1.4)),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.touch_app_rounded, size: 13, color: _goldDeep.withOpacity(.7)),
                              const SizedBox(width: 4),
                              Text(ta ? 'முழுசா படிக்க தட்டவும்' : 'Tap to read full',
                                  style: TextStyle(fontSize: 10.5, color: _goldDeep.withOpacity(.8), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Gold foil "seal" ribbon corner for TN items
              if (it.isTn)
                Positioned(
                  top: 0, right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(16)),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFFE9C158), _gold, _goldDeep]),
                        borderRadius: BorderRadius.only(
                            topRight: Radius.circular(15), bottomLeft: Radius.circular(12)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 12, color: Colors.white),
                          SizedBox(width: 3),
                          Text('TN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-content detail sheet — luxury parchment scroll look, opened when a
/// card is tapped so long content is never truncated.
class _CADetailSheet extends StatelessWidget {
  final CAItem item;
  final bool isTamil;
  final Map<String, String> catIcons;
  const _CADetailSheet({required this.item, required this.isTamil, required this.catIcons});

  @override
  Widget build(BuildContext context) {
    final ta = isTamil;
    final title = ta || item.titleEn.isEmpty ? item.titleTa : item.titleEn;
    final body = ta ? item.contentTa : item.contentEn;
    final altBody = ta ? item.contentEn : item.contentTa;

    return DraggableScrollableSheet(
      initialChildSize: .62,
      minChildSize: .35,
      maxChildSize: .92,
      expand: false,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: _parchment,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, -6))],
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 44, height: 5,
              decoration: BoxDecoration(color: const Color(0xFFDCD3B8), borderRadius: BorderRadius.circular(3)),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [Colors.white, Color(0xFFEFE7D2)]),
                            border: Border.all(color: const Color(0xFFE6DFC8)),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.1), blurRadius: 5, offset: const Offset(0, 2))],
                          ),
                          alignment: Alignment.center,
                          child: Text(catIcons[item.category] ?? '📰', style: const TextStyle(fontSize: 22)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('📅 ${item.date}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
                              if (item.isTn)
                                Container(
                                  margin: const EdgeInsets.only(top: 3),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFFE9C158), _gold]),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('⭐ தமிழ்நாடு / TN',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10.5)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: _ink, height: 1.35)),
                    const SizedBox(height: 12),
                    Container(height: 1.5, color: const Color(0xFFE6DFC8)),
                    const SizedBox(height: 14),
                    if (body.isNotEmpty)
                      Text(body, style: const TextStyle(fontSize: 15.5, color: _ink, height: 1.65)),
                    if (altBody.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(ta ? 'English' : 'தமிழில்',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _leaf, letterSpacing: .5)),
                      const SizedBox(height: 6),
                      Text(altBody, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.6)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
