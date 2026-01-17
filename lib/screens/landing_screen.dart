import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lens_fix/screens/login_screen.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Auth
import 'package:lens_fix/screens/home_screen.dart';
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // SMART NAVIGATION CHECK
    Timer(const Duration(seconds: 4), () {
      // Check if user is logged in
      User? user = FirebaseAuth.instance.currentUser;

      Widget nextScreen = (user != null) ? const HomeScreen() : const LoginScreen();

      Navigator.pushReplacement(
        context, 
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 1000),
          pageBuilder: (_, __, ___) => nextScreen, // Navigate dynamically
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. BACKGROUND ANIMATION (Rotating Tech Rings)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: TechRingPainter(_controller.value),
                size: Size.infinite,
              );
            },
          ),

          // 2. THE LOGO
          Center(
            child: ZoomIn(
              duration: const Duration(milliseconds: 1200),
              child: Container(
                width: 180, // Adjust size based on your image
                height: 180,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Optional: A subtle glow behind the logo itself
                  boxShadow: [
                    BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 50, spreadRadius: 10)
                  ],
                ),
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                  color: Colors.white, // Ensures the logo stays stark white
                ),
              ),
            ),
          ),
          
          // 3. TEXT (Optional Loading Indicator)
          Positioned(
            bottom: 50,
            child: FadeInUp(
              delay: const Duration(milliseconds: 1000),
              child: const Text(
                "INITIALIZING SYSTEMS...",
                style: TextStyle(
                  color: Colors.grey, 
                  letterSpacing: 4, 
                  fontSize: 10,
                  fontFamily: 'Courier'
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- CUSTOM PAINTER FOR THE "COOL BLACK ANIMATION" ---
class TechRingPainter extends CustomPainter {
  final double animationValue;
  TechRingPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05) // Very faint white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Ring 1: Large, Slow, Clockwise
    _drawDashedCircle(canvas, center, 150, paint, rotation: animationValue * 2 * pi);

    // Ring 2: Medium, Faster, Counter-Clockwise
    paint.color = Colors.white.withOpacity(0.08);
    paint.strokeWidth = 2;
    _drawDashedCircle(canvas, center, 110, paint, rotation: -animationValue * 4 * pi, dashCount: 8);

    // Ring 3: Small, Static or vibrating
    paint.color = Colors.white.withOpacity(0.15);
    canvas.drawCircle(center, 80, paint);
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Paint paint, {double rotation = 0, int dashCount = 12}) {
    final double gap = pi * 2 / dashCount;
    final double dashSize = gap / 2;
    
    for (int i = 0; i < dashCount; i++) {
      double startAngle = (gap * i) + rotation;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashSize,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TechRingPainter oldDelegate) => true;
}