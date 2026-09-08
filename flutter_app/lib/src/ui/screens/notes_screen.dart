import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/notes_service.dart';
import '../widgets/vetri_buttons.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String? _category;
  late Future<List<StudyNote>> _future;

  static const catMeta = {
    'schemes': ('📋', 'திட்டங்கள்', 'Schemes', Color(0xFF0F766E)),
    'gi_tags': ('🏷️', 'GI Tags', 'GI Tags', Color(0xFFB45309)),
    'current_affairs': ('📰', 'நடப்பு நிகழ்வுகள்', 'Current Affairs', Color(0xFFC9971C)),
    'science': ('🔬', 'அறிவியல்', 'Science', Color(0xFF7C3AED)),
    'committees': ('🏛️', 'குழுக்கள்', 'Committees', Color(0xFF1E6F46)),
    'awards': ('🎖️', 'விருதுகள்', 'Awards', Color(0xFFB45309)),
    'defence': ('🚀', 'பாதுகாப்பு', 'Defence', Color(0xFFDC2626)),
    'study_plan': ('📅', 'படிப்புத் திட்டம்', 'Study Plan', Color(0xFF2563EB)),
    'tamil_grammar': ('📖', 'தமிழ் இலக்கணம்', 'Tamil Grammar', Color(0xFF334155)),
    'general': ('📝', 'பொது', 'General', Color(0xFF334155)),
  };

  @override
  void initState() {
    super.initState();
    _future = NotesService.fetch();
  }

  void _filter(String? cat) {
    setState(() {
      _category = cat;
      _future = NotesService.fetch(category: cat);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ta = context.watch<AppProvider>().isTamil;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3EA),
      appBar: AppBar(title: Text(ta ? 'விரைவு குறிப்புகள்' : 'Quick Notes'), elevation: 0),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: VetriChip(
                    label: ta ? '✨ அனைத்தும்' : '✨ All',
                    selected: _category == null,
                    onTap: () => _filter(null),
                  ),
                ),
                for (final entry in catMeta.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: VetriChip(
                      label: '${entry.value.$1} ${ta ? entry.value.$2 : entry.value.$3}',
                      selected: _category == entry.key,
                      onTap: () => _filter(entry.key),
                    ),
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
                final notes = snap.data ?? [];
                if (notes.isEmpty) {
                  return Center(
                    child: Text(
                        ta ? 'இன்னும் குறிப்புகள் இல்லை.' : 'No notes yet.',
                        textAlign: TextAlign.center),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                  itemCount: notes.length,
                  itemBuilder: (c, i) => _NoteCard(note: notes[i], ta: ta, catMeta: catMeta),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatefulWidget {
  final StudyNote note;
  final bool ta;
  final Map<String, (String, String, String, Color)> catMeta;
  const _NoteCard({required this.note, required this.ta, required this.catMeta});
  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.note;
    final meta = widget.catMeta[n.category] ?? ('📝', 'பொது', 'General', const Color(0xFF334155));
    final title = widget.ta || n.titleEn.isEmpty ? n.titleTa : n.titleEn;
    final content = widget.ta || n.contentEn.isEmpty ? n.contentTa : n.contentEn;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
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
                        color: meta.$4.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(meta.$1, style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          Text(widget.ta ? meta.$2 : meta.$3,
                              style: TextStyle(
                                  fontSize: 11.5, fontWeight: FontWeight.w700, color: meta.$4)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (n.noteDate != null)
                      Text(n.noteDate!,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  ],
                ),
                const SizedBox(height: 10),
                Text(title,
                    maxLines: _expanded ? null : 2,
                    overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15.5, height: 1.35,
                        color: Color(0xFF14213D))),
                if (_expanded) ...[
                  const SizedBox(height: 10),
                  Container(height: 1, color: const Color(0xFFEFEAE0)),
                  const SizedBox(height: 10),
                  Text(content,
                      style: const TextStyle(fontSize: 13.5, height: 1.6, color: Color(0xFF4B5563))),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _expanded
                          ? (widget.ta ? 'குறைவாகக் காட்டு' : 'Show less')
                          : (widget.ta ? 'மேலும் படிக்க' : 'Read more'),
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: meta.$4),
                    ),
                    Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 18, color: meta.$4),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
