// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase with options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
  runApp(const RaseedApp());
}

class RaseedApp extends StatefulWidget {
  const RaseedApp({super.key});

  @override
  State<RaseedApp> createState() => _RaseedAppState();
}

class _RaseedAppState extends State<RaseedApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RASEED',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: const Color(0xFF6C5DD3),
          onPrimary: Colors.white,
          secondary: const Color(0xFFF7B801),
          onSecondary: Colors.white,
          error: Colors.redAccent,
          onError: Colors.white,
          background: const Color(0xFFF2F6FF),
          onBackground: Colors.black87,
          surface: Colors.white,
          onSurface: Colors.black87,
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F6FF),
        cardTheme: const CardThemeData(
          elevation: 6,
          color: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: const Color(0xFF8F97FB),
          onPrimary: Colors.black,
          secondary: const Color(0xFFCAFF70),
          onSecondary: Colors.black,
          error: Colors.redAccent,
          onError: Colors.white,
          background: const Color(0xFF232946),
          onBackground: Colors.white,
          surface: const Color(0xFF232946),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF232946),
        cardTheme: const CardThemeData(
          elevation: 6,
          color: Color(0xFF22223b),
        ),
      ),
      themeMode: _themeMode,
      home: StreamBuilder(
        stream: AuthService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          if (snapshot.hasData && snapshot.data != null) {
            // User is logged in
            return HomeScreen(
              userId: snapshot.data!.email ?? snapshot.data!.uid, // Use email if available, fallback to UID
              themeMode: _themeMode,
              onThemeToggle: _toggleTheme,
            );
          } else {
            // User is not logged in
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
