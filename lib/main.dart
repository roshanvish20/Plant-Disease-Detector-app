import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:demos/welcome/onboarding.dart';
import 'package:demos/welcome/signin.dart';
import 'package:demos/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bgqrggluhudsakkzpfku.supabase.co', // Replace with your Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJncXJnZ2x1aHVkc2Fra3pwZmt1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAwNzU4NDQsImV4cCI6MjA1NTY1MTg0NH0.kuPRw_dpSkl3k3yQjdXJb0TS1vgmzIXmSaU64fPP2uw', // Replace with your Supabase Anon Key
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Widget _initialScreen;

  @override
  void initState() {
    super.initState();
    _checkUserSession();
  }

  Future<void> _checkUserSession() async {
    final session = Supabase.instance.client.auth.currentSession;

    setState(() {
      if (session != null) {
        _initialScreen = const MainScreen();  // If session exists, go to MainScreen
      } else {
        _initialScreen = const Onboarding();  // Otherwise, show Onboarding
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Onboarding',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: _initialScreen,  // Dynamically decide which screen to show
      routes: {
        '/signin': (context) => const SignIN(),
        '/main_screen': (context) => const MainScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
