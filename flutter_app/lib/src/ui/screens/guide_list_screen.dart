import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/guide_service.dart';

const _ink = Color(0xFF14213D);

class GuideListScreen extends StatefulWidget {
  const GuideListScreen({super.key});
  @override
  State<GuideListScreen> createState() => _GuideListScreenState();
}

class _GuideListScreenState extends State<GuideListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 4, vsync: this);

  static const cats = ['govt_job', 'competitive', 'school', 'after_12th'];
  static const labelsTa = ['🏛️ அரசு வேலை', '🏦 போட்டித் தேர்வு', '📚 பள்ளித் தேர்வு', '🎓 12th-க்குப் பிறகு'];
  static const labelsEn = ['🏛️ Govt Jobs', '🏦 Competitive', '📚 School Exams', '🎓 After 12th'];

  Color _hex(String h) {
    final v = h.replaceFirst('#', '');
    return Color(int.parse('FF$v', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final ta = context.watch<AppProvider>().isTamil;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EE),
      appBar: AppBar(
        elevation: 0,
        title: Text(ta ? 'வழிகாட்டி' : 'Guide'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          indicatorColor: const Color(0xFFC9971C),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            for (int i = 0; i < cats.length; i++)
              Tab(text: ta ? labelsTa[i] : labelsEn[i]),
          ],
        ),
      ),
      body: FutureBuilder(
        future: GuideService.byCategory(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final byCat = snap.data!;
          return TabBarView(
            controller: _tab,
            children: [
              for (final c in cats) _list(byCat[c] ?? [], ta),
            ],
          );
        },
      ),
    );
  }

  Widget _list(List<ExamGuide> guides, bool ta) {
    if (guides.isEmpty) {
      return Center(child: Text(ta ? 'விரைவில் வரும்!' : 'Coming soon!'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: guides.length,
      itemBuilder: (context, i) {
        final g = guides[i];
        final color = _hex(g.colorHex);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 9, offset: const Offset(0, 3)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () => context.push('/guide/${g.examKey}'),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        gradient: LinearGradient(
                            colors: [color, color.withOpacity(.75)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight),
                      ),
                      alignment: Alignment.center,
                      child: Text(g.icon, style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ta ? g.nameTa : g.nameEn,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 3),
                          Text(ta ? g.ageLimitTa : g.ageLimitEn,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Color(0xFFF1ECDD), shape: BoxShape.circle),
                      child: const Icon(Icons.chevron_right_rounded, size: 20, color: _ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
