import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/guide_service.dart';
import '../widgets/vetri_buttons.dart';

const _ink = Color(0xFF14213D);
const _gold = Color(0xFFC9971C);
const _leaf = Color(0xFF2E7D4F);

class GuideDetailScreen extends StatelessWidget {
  final String examKey;
  const GuideDetailScreen({super.key, required this.examKey});

  Color _hex(String h) {
    final v = h.replaceFirst('#', '');
    return Color(int.parse('FF$v', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final ta = context.watch<AppProvider>().isTamil;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EE),
      body: FutureBuilder(
        future: GuideService.loadAll(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final g = snap.data!.firstWhere((x) => x.examKey == examKey,
              orElse: () => snap.data!.first);
          final color = _hex(g.colorHex);
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 130,
                backgroundColor: color,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
                  title: Text(ta ? g.nameTa : g.nameEn,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [color, color.withOpacity(.7)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    alignment: Alignment.center,
                    child: Text(g.icon, style: const TextStyle(fontSize: 40)),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(ta ? g.conductingBodyTa : g.conductingBodyEn,
                        style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 14),

                    if (g.examKey == 'after12_engineering')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: VetriButton(
                          label: ta ? '🧮 என் Cutoff கணக்கிடு' : '🧮 Calculate My Cutoff',
                          style: VetriButtonStyle.gold,
                          onPressed: () => context.push('/cutoff-calculator'),
                        ),
                      ),

                    _quickStats(ta, g),
                    const SizedBox(height: 16),

                    _section(ta ? '📋 தகுதி' : '📋 Eligibility', ta ? g.eligibilityTa : g.eligibilityEn),
                    _section(ta ? '🎂 வயது வரம்பு' : '🎂 Age Limit', ta ? g.ageLimitTa : g.ageLimitEn),
                    _bulletSection(ta ? '📝 தேர்வு அமைப்பு' : '📝 Exam Pattern',
                        ta ? g.patternListTa : g.patternListEn, Icons.assignment_outlined),
                    _bulletSection(ta ? '📚 பாடத்திட்டம்' : '📚 Syllabus',
                        ta ? g.syllabusListTa : g.syllabusListEn, Icons.menu_book_outlined),
                    _section(ta ? '✅ தேர்வு செயல்முறை' : '✅ Selection Process',
                        ta ? g.selectionProcessTa : g.selectionProcessEn),
                    _section(ta ? '💰 சம்பளம்' : '💰 Salary', ta ? g.salaryTa : g.salaryEn),

                    if ((ta ? g.prepTipsTa : g.prepTipsEn).isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4, bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9E8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border(left: BorderSide(color: _gold, width: 4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ta ? '💡 தயாராகும் முறை' : '💡 Preparation Tips',
                                style: const TextStyle(fontWeight: FontWeight.w800, color: _leaf)),
                            const SizedBox(height: 6),
                            Text(ta ? g.prepTipsTa : g.prepTipsEn,
                                style: const TextStyle(fontSize: 13.5, height: 1.5)),
                          ],
                        ),
                      ),

                    if (g.officialWebsite.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: const Color(0xFFEEF3FB), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const Icon(Icons.public, size: 18, color: Color(0xFF3E6FB0)),
                            const SizedBox(width: 8),
                            Text(ta ? 'அதிகாரப்பூர்வ இணையதளம்: ' : 'Official website: ',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            Text(g.officialWebsite,
                                style: const TextStyle(color: Color(0xFF3E6FB0), fontSize: 13)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _quickStats(bool ta, ExamGuide g) => Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 6)]),
              child: Column(children: [
                const Text('🎂', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 3),
                Text(ta ? g.ageLimitTa.split('·').first.trim() : g.ageLimitEn.split('·').first.trim(),
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 6)]),
              child: Column(children: [
                const Text('💰', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 3),
                Text(ta ? g.salaryTa : g.salaryEn,
                    textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ],
      );

  Widget _section(String title, String content) {
    if (content.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _ink)),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 13.5, height: 1.5)),
        ],
      ),
    );
  }

  Widget _bulletSection(String title, List<String> items, IconData icon) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _ink)),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: _leaf),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 13.5, height: 1.4))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
