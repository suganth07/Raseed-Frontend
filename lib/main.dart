// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/debug_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize debug settings to hide overflow indicators
  DebugUtils.initialize();
  
  // Suppress visual overflow errors globally (red/yellow boxes)
  ErrorWidget.builder = DebugUtils.customErrorWidgetBuilder;

  try {
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
      title: 'Raseed',
      debugShowCheckedModeBanner: false,
      // Global builder to handle overflow gracefully
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8), // Google Blue
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Roboto', fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25),
          displayMedium: TextStyle(fontFamily: 'Roboto', fontSize: 45, fontWeight: FontWeight.w400),
          displaySmall: TextStyle(fontFamily: 'Roboto', fontSize: 36, fontWeight: FontWeight.w400),
          headlineLarge: TextStyle(fontFamily: 'Roboto', fontSize: 32, fontWeight: FontWeight.w400),
          headlineMedium: TextStyle(fontFamily: 'Roboto', fontSize: 28, fontWeight: FontWeight.w400),
          headlineSmall: TextStyle(fontFamily: 'Roboto', fontSize: 24, fontWeight: FontWeight.w400),
          titleLarge: TextStyle(fontFamily: 'Roboto', fontSize: 22, fontWeight: FontWeight.w500),
          titleMedium: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15),
          titleSmall: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
          bodyLarge: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
          bodyMedium: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
          bodySmall: TextStyle(fontFamily: 'Roboto', fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
          labelLarge: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
          labelMedium: TextStyle(fontFamily: 'Roboto', fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
          labelSmall: TextStyle(fontFamily: 'Roboto', fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 3,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: Color(0xFF1D1B20),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            minimumSize: const Size(0, 40), // Smaller height for desktop
            textStyle: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            minimumSize: const Size(0, 40), // Smaller height for desktop
            textStyle: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            minimumSize: const Size(0, 40), // Smaller height for desktop
            textStyle: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          shape: CircleBorder(),
          elevation: 6,
          highlightElevation: 12,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          elevation: 3,
          selectedLabelStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 3,
          height: 76, // Reduced from 80 to fix overflow
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                fontWeight: FontWeight.w500,
              );
            }
            return const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              fontWeight: FontWeight.w400,
            );
          }),
        ),
        chipTheme: const ChipThemeData(
          shape: StadiumBorder(),
          labelStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        dividerTheme: const DividerThemeData(
          thickness: 1,
          space: 1,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8AB4F8),
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Roboto', fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25, color: Colors.white),
          displayMedium: TextStyle(fontFamily: 'Roboto', fontSize: 45, fontWeight: FontWeight.w400, color: Colors.white),
          displaySmall: TextStyle(fontFamily: 'Roboto', fontSize: 36, fontWeight: FontWeight.w400, color: Colors.white),
          headlineLarge: TextStyle(fontFamily: 'Roboto', fontSize: 32, fontWeight: FontWeight.w400, color: Colors.white),
          headlineMedium: TextStyle(fontFamily: 'Roboto', fontSize: 28, fontWeight: FontWeight.w400, color: Colors.white),
          headlineSmall: TextStyle(fontFamily: 'Roboto', fontSize: 24, fontWeight: FontWeight.w400, color: Colors.white),
          titleLarge: TextStyle(fontFamily: 'Roboto', fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white),
          titleMedium: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15, color: Colors.white),
          titleSmall: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: Colors.white),
          bodyLarge: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5, color: Colors.white70),
          bodyMedium: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, color: Colors.white70),
          bodySmall: TextStyle(fontFamily: 'Roboto', fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4, color: Colors.white70),
          labelLarge: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: Colors.white),
          labelMedium: TextStyle(fontFamily: 'Roboto', fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: Colors.white),
          labelSmall: TextStyle(fontFamily: 'Roboto', fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: Colors.white),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 3,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
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
