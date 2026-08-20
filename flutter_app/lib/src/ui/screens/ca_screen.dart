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

  @override
  Widget build(BuildContext context) {
    final ta = context.watch<AppProvider>().isTamil;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EE),
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
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final e in byDate.entries) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('📅 ${e.key}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF14213D))),
                      ),
                      for (final it in e.value)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            shape: it.isTn
                                ? RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                        color: Color(0xFFC9971C), width: 1.5))
                                : RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                              leading: Text(catIcons[it.category] ?? '📰',
                                  style: const TextStyle(fontSize: 24)),
                              title: Text(ta || it.titleEn.isEmpty
                                      ? it.titleTa
                                      : it.titleEn,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              trailing: it.isTn
                                  ? const Text('⭐ TN',
                                      style: TextStyle(
                                          color: Color(0xFFC9971C),
                                          fontWeight: FontWeight.w800))
                                  : const Icon(Icons.expand_more),
                              children: [
                                if ((ta ? it.contentTa : it.contentEn).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(ta ? it.contentTa : it.contentEn),
                                    ),
                                  ),
                              ],
                            ),
                          ),
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
