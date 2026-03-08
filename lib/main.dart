import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0C6B58),
        secondary: Color(0xFFF09A36),
        surface: Color(0xFFFFFCF5),
        onSurface: Color(0xFF162218),
      ),
    );

    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..initialize(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TaskFlow',
        theme: base.copyWith(
          scaffoldBackgroundColor: const Color(0xFFF7F3EB),
          textTheme: GoogleFonts.manropeTextTheme(base.textTheme),
          appBarTheme: AppBarTheme(
            centerTitle: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: base.colorScheme.onSurface,
            titleTextStyle: GoogleFonts.spaceGrotesk(
              color: base.colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white.withValues(alpha: 0.9),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: const Color(0xFFDDE5DA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: base.colorScheme.primary,
                width: 1.4,
              ),
            ),
          ),
        ),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isInitializing) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (auth.isAuthenticated) {
              return const HomeScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
