import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  const url = String.fromEnvironment('SUPABASE_URL');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isEmpty || anonKey.isEmpty) {
    runApp(MaterialApp(theme: buildGinulisTheme(), home: const Scaffold(
      body: Center(child: Text('Supabase belum dikonfigurasi. Jalankan dengan config.json.')),
    )));
    return;
  }
  await Supabase.initialize(url: url, anonKey: anonKey);
  runApp(const GinulisApp());
}

class GinulisApp extends StatelessWidget {
  const GinulisApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Ginulis.id',
    debugShowCheckedModeBanner: false,
    theme: buildGinulisTheme(),
    home: const AuthGate(),
  );
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _subscription;
  @override
  void initState() {
    super.initState();
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
  }
  @override
  void dispose() { _subscription.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) =>
      Supabase.instance.client.auth.currentSession == null
          ? const LoginScreen() : const HomeScreen();
}
