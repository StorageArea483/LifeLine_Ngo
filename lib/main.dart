import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:life_line_ngo/firebase_options.dart';
import 'package:life_line_ngo/widgets/login_signup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Increase channel buffer size to prevent lifecycle messages from being discarded
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Error: $error');
    return true;
  };

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: 'https://npczrptqrtrbyqhzptil.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5wY3pycHRxcnRyYnlxaHpwdGlsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ2Nzg1NzgsImV4cCI6MjA4MDI1NDU3OH0.ZGxwwksLTeTqZ1cxoP7nj-dG2sRMzCmPVJt4ovO5y3Q',
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginSignup(),
    );
  }
}
