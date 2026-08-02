import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../widgets/vetri_buttons.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _register() async {
    if (_name.text.trim().isEmpty ||
        _mobile.text.length != 10 ||
        _password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('பெயர், 10-இலக்க எண், 6+ கடவுச்சொல் தேவை')));
      return;
    }
    setState(() => _loading = true);
    final (ok, msg) = await AuthService()
        .register(_name.text.trim(), _mobile.text, _password.text);
    setState(() => _loading = false);
    if (!mounted) return;
    if (ok) {
      context.go('/dashboard');
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(msg)));
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D4F)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFFE0D8C4), width: 1.4)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: Color(0xFF2E7D4F), width: 2)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7EE),
      appBar: AppBar(title: const Text('பதிவு / Sign up'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              decoration: _dec('பெயர் / Name', Icons.person_outline),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _mobile,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: _dec('கைபேசி எண் / Mobile', Icons.phone_android)
                  .copyWith(counterText: ''),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _password,
              obscureText: _obscure,
              decoration: _dec('கடவுச்சொல் / Password', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade500),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 26),
            VetriButton(
              label: 'கணக்கு உருவாக்கு / Create account',
              icon: Icons.check_circle_outline,
              loading: _loading,
              onPressed: _register,
            ),
          ],
        ),
      ),
    );
  }
}
