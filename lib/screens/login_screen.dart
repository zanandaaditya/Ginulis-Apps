import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _hide = true;

  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi email dan kata sandi.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(), password: _password.text,
      );
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Login gagal. Periksa email dan kata sandi.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Padding(padding: const EdgeInsets.all(25), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: double.infinity, height: 210,
            decoration: BoxDecoration(gradient: const LinearGradient(
              colors: [Color(0xFF8F91FF), Color(0xFF514BE0)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(27)),
            child: Stack(children: [
              const Positioned(top: 20, left: 22, child: Text('ginulis.id',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
              Positioned(right: 27, bottom: 28, child: Icon(Icons.dashboard_customize_rounded,
                color: Colors.white.withValues(alpha: .8), size: 90)),
              const Positioned(left: 22, bottom: 29, child: Text('Pesanan tertata.\nPekerjaan lebih mudah.',
                style: TextStyle(color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.w800, height: 1.25))),
            ]),
          ),
          const SizedBox(height: 35),
          const Text('Selamat datang 👋',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 7),
          const Text('Masuk untuk mengelola pesanan Ginulis.id',
            style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 25),
          TextField(controller: _email, keyboardType: TextInputType.emailAddress,
            autocorrect: false, decoration: const InputDecoration(labelText: 'Email pemilik',
              prefixIcon: Icon(Icons.mail_outline_rounded))),
          const SizedBox(height: 13),
          TextField(controller: _password, obscureText: _hide,
            onSubmitted: (_) => _loading ? null : _login(),
            decoration: InputDecoration(labelText: 'Kata sandi',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(tooltip: 'Tampilkan atau sembunyikan kata sandi',
                onPressed: () => setState(() => _hide = !_hide),
                icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: FilledButton(
            onPressed: _loading ? null : _login,
            child: Text(_loading ? 'Memproses...' : 'Masuk ke Ginulis.id'))),
          const SizedBox(height: 19),
          const Center(child: Text('Aplikasi pribadi • Ginulis.id',
            style: TextStyle(fontSize: 11, color: AppColors.muted))),
        ],
      )),
    )))),
  );
}
