import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart'; 
import 'package:lens_fix/screens/home_screen.dart';
import 'package:lens_fix/services/auth_service.dart'; // Import the service

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService(); // Connect to Firebase
  
  bool _isLoading = false; // Controls the spinner

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 1. Basic Validation
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter Email & Password"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // 2. Start Loading
    setState(() => _isLoading = true);

    try {
      // 3. Attempt Login with Firebase
      await _authService.signIn(email, password);

      // 4. Success? Go to Home
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));

    } on FirebaseAuthException catch (e) {
      // 5. Firebase Error (Wrong password, user not found)
      String message = "Authentication Failed";
      if (e.code == 'user-not-found') message = "User not found. Contact Admin.";
      if (e.code == 'wrong-password') message = "Incorrect Password.";
      if (e.code == 'invalid-email') message = "Invalid Email Format.";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      // Generic Error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.redAccent),
      );
    } finally {
      // 6. Stop Loading (if we haven't navigated away)
      if (mounted) setState(() => _isLoading = false);
    }
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
                    ZoomIn(
                      duration: const Duration(milliseconds: 800),
                      child: Container(
                        height: 140, width: 140,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 20)],
                        ),
                        child: Image.asset('assets/logo.png', color: Colors.white, fit: BoxFit.contain),
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

            // BOTTOM SECTION: LOGIN PANEL
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
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Welcome Back", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                        const SizedBox(height: 20),
                        
                        _buildTextField("College Email", Icons.alternate_email, _emailController),
                        const SizedBox(height: 15),
                        _buildTextField("Password", Icons.lock_outline, _passwordController, isPassword: true),
                        
                        const SizedBox(height: 30),
                        
                        // LOGIN BUTTON (With Spinner)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin, // Disable if loading
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading 
                              ? const SizedBox(
                                  height: 20, width: 20, 
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)
                                )
                              : const Text("ENTER CAMPUS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ),
                      ],
                    ),
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
        fillColor: Colors.black, 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)), 
      ),
    );
  }
}