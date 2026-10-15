import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../widgets/vetri_buttons.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _mobile = TextEditingController();
  final _name = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false, _obscure = true, _sent = false;

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D4F)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFE0D8C4), width: 1.4)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFF2E7D4F), width: 2)),
      );

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

  Future<void> _submit() async {
    if (_mobile.text.length != 10 || _name.text.trim().isEmpty || _pass.text.length < 6) {
      _snack('10 இலக்க எண், பெயர், புதிய கடவுச்சொல் (6+) உள்ளிடவும்');
      return;
    }
    setState(() => _loading = true);
    final (ok, msg) = await AuthService().forgotPassword(_mobile.text, _name.text.trim(), _pass.text);
    if (!mounted) return;
    setState(() { _loading = false; _sent = ok; });
    if (!ok) _snack(msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EE),
      appBar: AppBar(title: const Text('கடவுச்சொல் மீட்பு / Reset password'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _sent ? _done(context) : _form(),
        ),
      ),
    );
  }

  Widget _done(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.mark_email_read_rounded, size: 72, color: Color(0xFF2E7D4F)),
          const SizedBox(height: 16),
          const Text('கோரிக்கை பெறப்பட்டது',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(
              'நிர்வாகி அனுமதித்தவுடன் புதிய கடவுச்சொல்லுடன் உள்நுழையலாம்.\n'
              'Once the admin approves, log in with your NEW password.\n\n'
              '(பதிவு செய்த பெயர் சரியாக இருந்தால் மட்டுமே கோரிக்கை பதிவாகும்.)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
          const SizedBox(height: 26),
          VetriButton(label: 'உள்நுழைவுக்குத் திரும்பு', onPressed: () => context.go('/login')),
        ],
      );

  Widget _form() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('பதிவு செய்த கைபேசி எண், பெயர் மற்றும் புதிய கடவுச்சொல்லை உள்ளிடவும். '
              'நிர்வாகி சரிபார்த்து அனுமதிப்பார்.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.45)),
          const SizedBox(height: 20),
          TextField(
            controller: _mobile,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: _dec('கைபேசி எண் / Mobile', Icons.phone_android).copyWith(counterText: ''),
          ),
          const SizedBox(height: 14),
          TextField(controller: _name, decoration: _dec('பதிவு செய்த பெயர் / Registered name', Icons.person_outline)),
          const SizedBox(height: 14),
          TextField(
            controller: _pass,
            obscureText: _obscure,
            decoration: _dec('புதிய கடவுச்சொல் / New password', Icons.lock_reset).copyWith(
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade500),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 24),
          VetriButton(label: 'கோரிக்கை அனுப்பு / Submit', icon: Icons.send_rounded, loading: _loading, onPressed: _submit),
        ],
      );
}
