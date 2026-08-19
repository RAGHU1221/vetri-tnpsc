import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../widgets/vetri_buttons.dart';

const _ink = Color(0xFF14213D);
const _gold = Color(0xFFC9971C);
const _leaf = Color(0xFF2E7D4F);
const _verm = Color(0xFFB33A2B);
const _sky = Color(0xFF3E6FB0);

/// Live TNEA Engineering Cutoff Calculator
/// Formula (real, DoTE Tamil Nadu): Maths + (Physics/2) + (Chemistry/2) = out of 200
class CutoffCalculatorScreen extends StatefulWidget {
  const CutoffCalculatorScreen({super.key});
  @override
  State<CutoffCalculatorScreen> createState() => _CutoffCalculatorScreenState();
}

class _CutoffCalculatorScreenState extends State<CutoffCalculatorScreen> {
  final _maths = TextEditingController();
  final _physics = TextEditingController();
  final _chemistry = TextEditingController();
  double? _cutoff;

  double? _num(String s) => double.tryParse(s.trim());

  void _calculate() {
    final m = _num(_maths.text);
    final p = _num(_physics.text);
    final c = _num(_chemistry.text);
    if (m == null || p == null || c == null ||
        m < 0 || m > 100 || p < 0 || p > 100 || c < 0 || c > 100) {
      setState(() => _cutoff = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(context.read<AppProvider>().isTamil
              ? '0-100 வரம்பில் மூன்று மதிப்பெண்களையும் உள்ளிடவும்'
              : 'Enter all three marks between 0-100')));
      return;
    }
    setState(() => _cutoff = m + (p / 2) + (c / 2));
  }

  String _band(double c, bool ta) {
    if (c >= 180) return ta ? '🟢 மிக உயர்ந்த வரம்பு — top-tier கல்லூரிகள்/branches வாய்ப்பு அதிகம்' : '🟢 Very high range — good chance at top-tier colleges/branches';
    if (c >= 150) return ta ? '🔵 நல்ல வரம்பு — பல நல்ல கல்லூரிகளில் CSE/IT/ECE வாய்ப்பு' : '🔵 Good range — decent chance at CSE/IT/ECE in many good colleges';
    if (c >= 120) return ta ? '🟡 சராசரி வரம்பு — Mech/Civil/EEE அல்லது Tier-2 கல்லூரிகளில் CSE வாய்ப்பு' : '🟡 Average range — Mech/Civil/EEE or CSE in Tier-2 colleges likely';
    if (c >= 90) return ta ? '🟠 அடிப்படை வரம்பு — self-financing கல்லூரிகளில் seat கிடைக்கலாம்' : '🟠 Basic range — seats likely in self-financing colleges';
    return ta ? '🔴 குறைந்த வரம்பு — polytechnic/BCA/B.Sc போன்ற மாற்று வழிகளையும் யோசியுங்கள்' : '🔴 Lower range — also consider alternatives like polytechnic/BCA/B.Sc';
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0D8C4), width: 1.4)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _leaf, width: 2)),
      );

  @override
  Widget build(BuildContext context) {
    final ta = context.watch<AppProvider>().isTamil;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EE),
      appBar: AppBar(
          title: Text(ta ? '🧮 TNEA Cutoff Calculator' : '🧮 TNEA Cutoff Calculator'),
          elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(color: const Color(0xFFEEF3FB), borderRadius: BorderRadius.circular(10)),
            child: Text(
                ta
                    ? '📐 Formula: Maths + (Physics ÷ 2) + (Chemistry ÷ 2) = 200-ல் மதிப்பெண்'
                    : '📐 Formula: Maths + (Physics ÷ 2) + (Chemistry ÷ 2) = score out of 200',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _sky)),
          ),
          TextField(
            controller: _maths,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _dec(ta ? 'கணிதம் (Maths) மதிப்பெண் /100' : 'Mathematics mark /100'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _physics,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _dec(ta ? 'இயற்பியல் (Physics) மதிப்பெண் /100' : 'Physics mark /100'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _chemistry,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _dec(ta ? 'வேதியியல் (Chemistry) மதிப்பெண் /100' : 'Chemistry mark /100'),
          ),
          const SizedBox(height: 20),
          VetriButton(
            label: ta ? 'Cutoff கணக்கிடு' : 'Calculate Cutoff',
            icon: Icons.calculate_rounded,
            onPressed: _calculate,
          ),
          if (_cutoff != null) ...[
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_leaf, Color(0xFF1F5C38)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: _leaf.withOpacity(.35), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Column(
                children: [
                  Text(ta ? 'உங்கள் TNEA Cutoff' : 'Your TNEA Cutoff',
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('${_cutoff!.toStringAsFixed(1)} / 200',
                      style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 8)]),
              child: Text(_band(_cutoff!, ta), style: const TextStyle(fontSize: 13.5, height: 1.5)),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E8),
              borderRadius: BorderRadius.circular(11),
              border: Border(left: BorderSide(color: _gold, width: 4)),
            ),
            child: Text(
                ta
                    ? '⚠️ இது ஒப்பீட்டு வழிகாட்டி மட்டுமே. உண்மையான college/branch admission unga category (OC/BC/MBC/SC/ST), district, மற்றும் round-wise seat demand-ஐ பொறுத்து மாறும். இறுதி முடிவுக்கு tneaonline.org பாருங்க.'
                    : '⚠️ This is a comparative guide only. Actual college/branch admission depends on your category (OC/BC/MBC/SC/ST), district, and round-wise seat demand. Check tneaonline.org for the final word.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
