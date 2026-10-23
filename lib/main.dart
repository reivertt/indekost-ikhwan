import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/app_config.dart';
import 'firebase_options.dart';
import 'pages/home_shell.dart';
import 'pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  AppConfig.paymentDueSoonDays = prefs.getInt('paymentDueSoonDays') ?? 30;
  AppConfig.bathroomDueDays = prefs.getInt('bathroomDueDays') ?? 7;
  AppConfig.airConDueDays = prefs.getInt('airConDueDays') ?? 180;
  AppConfig.maintenanceDueDays = prefs.getInt('maintenanceDueDays') ?? 730;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) return const HomeShell();
          return const LoginPage();
        },
      ),
    );
  }
}
