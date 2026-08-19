import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/ai_service.dart';
import '../widgets/vetri_buttons.dart';

class AIChatScreen extends StatefulWidget {
  final String? initialQuestion;
  const AIChatScreen({super.key, this.initialQuestion});
  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _waiting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuestion != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _send(widget.initialQuestion!));
    }
  }

  Future<void> _send(String text) async {
    text = text.trim();
    if (text.isEmpty || _waiting) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _waiting = true;
    });
    _controller.clear();
    _scrollDown();
    final reply = await AIService.chat(_messages);
    if (!mounted) return;
    setState(() {
      _messages.add({'role': 'assistant', 'content': reply});
      _waiting = false;
    });
    _scrollDown();
  }

  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
        }
      });

  @override
  Widget build(BuildContext context) {
    final ta = context.watch<AppProvider>().isTamil;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EE),
      appBar: AppBar(title: Text(ta ? '🤖 AI ஆசிரியர்' : '🤖 AI Tutor'), elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🤖', style: TextStyle(fontSize: 52)),
                          const SizedBox(height: 8),
                          Text(
                              ta
                                  ? 'வணக்கம்! TNPSC சந்தேகங்களை தமிழில் கேளுங்கள்.\n\nஉதா: "73வது திருத்தம் பற்றி விளக்கு"\n"திருக்குறள் பால்கள் என்ன?"'
                                  : 'Hi! Ask your TNPSC doubts in Tamil or English.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length + (_waiting ? 1 : 0),
                    itemBuilder: (c, i) {
                      if (i == _messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(children: [
                            SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 10),
                            Text('யோசிக்கிறேன்…'),
                          ]),
                        );
                      }
                      final m = _messages[i];
                      final isUser = m['role'] == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.82),
                          decoration: BoxDecoration(
                            color: isUser
                                ? const Color(0xFF2E7D4F)
                                : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft: Radius.circular(isUser ? 14 : 3),
                              bottomRight: Radius.circular(isUser ? 3 : 14),
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(.06),
                                  blurRadius: 5)
                            ],
                          ),
                          child: SelectableText(m['content'] ?? '',
                              style: TextStyle(
                                  fontSize: 15.5,
                                  height: 1.6,
                                  color: isUser
                                      ? Colors.white
                                      : const Color(0xFF14213D))),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1, maxLines: 4,
                      decoration: InputDecoration(
                        hintText: ta
                            ? 'சந்தேகம் கேளுங்கள்…'
                            : 'Ask a doubt…',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: _send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  VetriIconButton(
                    icon: Icons.send_rounded,
                    size: 48,
                    onTap: _waiting ? null : () => _send(_controller.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
