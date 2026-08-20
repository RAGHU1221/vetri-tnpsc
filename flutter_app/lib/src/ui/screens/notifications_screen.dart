import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_provider.dart';
import '../../services/job_notification_service.dart';

const _ink = Color(0xFF14213D);
const _gold = Color(0xFFC9971C);
const _leaf = Color(0xFF2E7D4F);
const _verm = Color(0xFFB33A2B);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<JobNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = JobNotificationService.fetchAll();
  }

  Future<void> _openLink(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Color _statusColor(String s) => switch (s) {
        'open' => _leaf,
        'closed' => Colors.grey,
        _ => _gold, // upcoming
      };

  String _statusLabel(String s, bool ta) => switch (s) {
        'open' => ta ? '🟢 விண்ணப்பிக்கலாம்' : '🟢 Applications Open',
        'closed' => ta ? '⚪ முடிந்தது' : '⚪ Closed',
        _ => ta ? '🟡 விரைவில்' : '🟡 Upcoming',
      };

  @override
  Widget build(BuildContext context) {
    final ta = context.watch<AppProvider>().isTamil;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EE),
      appBar: AppBar(
        title: Text(ta ? '🔔 அறிவிப்புகள்' : '🔔 Notifications'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _future = JobNotificationService.fetchAll()),
          ),
        ],
      ),
      body: FutureBuilder(
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
                        ? '🔕 தற்போது அறிவிப்புகள் இல்லை.\nபுதிய notification வந்தவுடன் இங்கே தெரியும்!'
                        : '🔕 No notifications right now.\nNew ones will appear here as soon as published!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final n = items[i];
              final color = _statusColor(n.status);
              final daysLeft = n.daysLeft;
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: color.withOpacity(.3), width: 1.4),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(ta ? n.titleTa : n.titleEn,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: color.withOpacity(.15), borderRadius: BorderRadius.circular(14)),
                            child: Text(_statusLabel(n.status, ta),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 14, runSpacing: 6,
                        children: [
                          if (n.vacancies != null)
                            _infoChip('💼', ta ? '${n.vacancies} காலியிடங்கள்' : '${n.vacancies} vacancies'),
                          if (n.applicationEnd != null)
                            _infoChip('📅', ta ? 'கடைசி தேதி: ${n.applicationEnd}' : 'Last date: ${n.applicationEnd}'),
                          if (n.examDate != null)
                            _infoChip('📝', ta ? 'தேர்வு: ${n.examDate}' : 'Exam: ${n.examDate}'),
                        ],
                      ),
                      if (daysLeft != null && daysLeft >= 0 && n.status == 'open')
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                              color: daysLeft <= 3 ? const Color(0xFFFDECEA) : const Color(0xFFFFF9E8),
                              borderRadius: BorderRadius.circular(9)),
                          child: Text(
                              ta ? '⏰ இன்னும் $daysLeft நாட்கள் மட்டுமே!' : '⏰ Only $daysLeft days left!',
                              style: TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w800,
                                  color: daysLeft <= 3 ? _verm : const Color(0xFF9A7413))),
                        ),
                      if ((ta ? n.notesTa : n.notesEn).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(ta ? n.notesTa : n.notesEn,
                              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (n.applicationLink.isNotEmpty)
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _openLink(n.applicationLink),
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: Text(ta ? 'விண்ணப்பிக்க' : 'Apply Now',
                                    style: const TextStyle(fontSize: 13)),
                                style: FilledButton.styleFrom(
                                    backgroundColor: _leaf,
                                    minimumSize: const Size.fromHeight(40)),
                              ),
                            ),
                          if (n.officialLink.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _openLink(n.officialLink),
                                icon: const Icon(Icons.description_outlined, size: 16),
                                label: Text(ta ? 'அறிவிப்பு PDF' : 'Notification PDF',
                                    style: const TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoChip(String emoji, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _ink)),
        ],
      );
}
