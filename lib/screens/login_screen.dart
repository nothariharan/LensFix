import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart'; // For animations
import 'package:lens_fix/screens/home_screen.dart'; // Student Flow
// import 'package:lens_fix/screens/admin_dashboard.dart'; // Admin Flow (Coming Soon)

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleLogin() {
    // 🧠 HACKATHON LOGIC: "Fake" Authentication
    final email = _emailController.text.toLowerCase();

    if (email.contains("admin")) {
      // TODO: Navigate to Admin Dashboard
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🚀 Welcome back, Admin!")),
      );
    } else {
      // Default to Student Dashboard
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background gradient for depth
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F111A), // Deep Dark
              Color(0xFF1A1D2D), // Slightly Lighter
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- TOP SECTION: ART & BRANDING ---
              Expanded(
                flex: 5,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Logo
                      ZoomIn(
                        duration: const Duration(milliseconds: 800),
                        child: Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: Icon(
                          Icons.camera_alt, // <--- Use this valid icon instead
                          size: 60,
                          color: Theme.of(context).primaryColor
                        ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Animated Text
                      FadeInUp(
                        delay: const Duration(milliseconds: 300),
                        child: Text(
                          "LENSFIX",
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                      ),
                      FadeInUp(
                        delay: const Duration(milliseconds: 500),
                        child: Text(
                          "SEE IT. SNAP IT. SOLVED.",
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).primaryColor,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- BOTTOM SECTION: LOGIN PANEL ---
              Expanded(
                flex: 4,
                child: FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E212B), // Card Color
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, -5))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Welcome Back", style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        
                        // Email Field
                        _buildTextField("College Email", Icons.alternate_email, _emailController),
                        const SizedBox(height: 15),
                        
                        // Password Field
                        _buildTextField("Password", Icons.lock_outline, _passwordController, isPassword: true),
                        
                        const Spacer(),
                        
                        // The "Cyber" Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleLogin,
                            child: const Text("ENTER CAMPUS"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF0F111A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00F0FF)), // Neon Cyan focus
        ),
      ),
    );
  }
}