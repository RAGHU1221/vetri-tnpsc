import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../widgets/vetri_buttons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _login() async {
    if (_mobile.text.length != 10 || _password.text.length < 6) {
      _snack('சரியான எண் & கடவுச்சொல் உள்ளிடவும்');
      return;
    }
    setState(() => _loading = true);
    final (ok, msg) = await AuthService().login(_mobile.text, _password.text);
    setState(() => _loading = false);
    if (!mounted) return;
    ok ? context.go('/dashboard') : _snack(msg);
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFE7D2), Color(0xFFFBF7EE)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 92, height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                          colors: [Color(0xFF2E7D4F), Color(0xFF1F5C38)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF2E7D4F).withOpacity(.35),
                            blurRadius: 22, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: const Icon(Icons.school, size: 46, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 18),
                Text('வெற்றி TNPSC',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF14213D))),
                Text('தமிழ் & English தேர்வு தயாரிப்பு',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14.5)),
                const SizedBox(height: 38),
                TextField(
                  controller: _mobile,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration:
                      _dec('கைபேசி எண் / Mobile', Icons.phone_android).copyWith(counterText: ''),
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
                  label: 'உள்நுழை / Login',
                  icon: Icons.arrow_forward_rounded,
                  loading: _loading,
                  onPressed: _login,
                ),
                const SizedBox(height: 14),
                VetriButton(
                  label: 'புதிய கணக்கு? பதிவு செய்',
                  style: VetriButtonStyle.ghost,
                  onPressed: () => context.push('/signup'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
