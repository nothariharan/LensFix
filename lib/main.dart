import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lens_fix/screens/login_screen.dart';
import 'package:lens_fix/screens/landing_screen.dart';
void main() {
  // 1. We call the class "LensFixApp" here
  runApp(const LensFixApp());
}

// 2. We define the class "LensFixApp" here
class LensFixApp extends StatelessWidget {
  const LensFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LensFix',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, 
      
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F111A),
        primaryColor: const Color(0xFF00F0FF),
        
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F0FF),
          secondary: Color(0xFFFF2E63),
          surface: Color(0xFF1E212B),
        ),

        textTheme: TextTheme(
          displayLarge: GoogleFonts.bebasNeue(
            fontSize: 56, 
            color: Colors.white,
            letterSpacing: 2,
          ),
          bodyLarge: GoogleFonts.outfit(
            fontSize: 18, 
            color: Colors.white70
          ),
          labelLarge: GoogleFonts.outfit(
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00F0FF),
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
      ),
      
      home: const LandingScreen(),
    );
  }
}