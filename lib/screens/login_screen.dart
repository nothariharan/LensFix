import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart'; 
import 'package:lens_fix/screens/home_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleLogin() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // NOIR THEME
      body: SafeArea(
        child: Column(
          children: [
            // TOP SECTION: LOGO
            Expanded(
              flex: 5,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- UPDATED LOGO SECTION ---
                    ZoomIn(
                      duration: const Duration(milliseconds: 800),
                      child: Container(
                        height: 140, width: 140, // Slightly larger
                        padding: const EdgeInsets.all(10), // Padding inside the circle
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2), // Thin White Border
                          boxShadow: [
                             BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 20)
                          ]
                        ),
                        child: Image.asset(
                          'assets/logo.png', // <--- YOUR NEW LOGO
                          color: Colors.white, // Ensure it matches the theme
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    FadeInUp(
                      child: Text("LENSFIX", style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
                    ),
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: const Text("SEE IT. SNAP IT. SOLVED.", style: TextStyle(color: Colors.grey, letterSpacing: 3)),
                    ),
                  ],
                ),
              ),
            ),

            // BOTTOM SECTION: LOGIN
            Expanded(
              flex: 4,
              child: FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: const BoxDecoration(
                    color: Color(0xFF111111), // Dark Grey Panel
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Welcome Back", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                      const SizedBox(height: 20),
                      _buildTextField("College Email", Icons.alternate_email, _emailController),
                      const SizedBox(height: 15),
                      _buildTextField("Password", Icons.lock_outline, _passwordController, isPassword: true),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, // White Button
                            foregroundColor: Colors.black, // Black Text
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("ENTER CAMPUS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
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
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.black, // Inner Black
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)), // White Focus
      ),
    );
  }
}