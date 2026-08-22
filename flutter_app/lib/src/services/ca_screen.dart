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
/// emb
