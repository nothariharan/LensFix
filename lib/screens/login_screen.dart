import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart'; 
import 'package:lens_fix/screens/home_screen.dart';
import 'package:lens_fix/services/auth_service.dart';
import 'package:lens_fix/services/database_service.dart'; 
import 'package:lens_fix/screens/helper_home_screen.dart';
import 'package:lens_fix/screens/admin_dashboard_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dbService = DatabaseService(); 
  
  bool _isLoading = false;
  bool _isObscured = true; 
  bool _isLoginMode = true; // TOGGLE STATE
  String _selectedRole = 'Student';
  final List<String> _roles = ['Student', 'Helper', 'Admin'];

  // --- REWRITTEN AUTH LOGIC ---
  Future<void> _processAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Valid email & 6+ char password required")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        // LOGIN PATH
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      } else {
        // SIGN UP PATH: Check Pre-Authorization first
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          throw "ACCESS DENIED: Email not authorized by Admin.";
        }
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      }

      // SYNC DATA (This now handles the UID migration)
      await _dbService.ensureUserExists(_selectedRole);
      
      if (!mounted) return;
      _routeUser();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _routeUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    String role = (userDoc.data() as Map<String, dynamic>)['role'] ?? 'student';

    if (!mounted) return;
    if (role.toLowerCase() == 'helper') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HelperHomeScreen()));
    } else if (role.toLowerCase() == 'admin') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ZoomIn(duration: const Duration(milliseconds: 800), child: Container(height: 140, width: 140, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 20)]), child: Image.asset('assets/logo.png', color: Colors.white, fit: BoxFit.contain))),
                              const SizedBox(height: 30),
                              FadeInUp(child: Text("LENSFIX", style: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Courier'))),
                              FadeInUp(delay: const Duration(milliseconds: 200), child: const Text("SEE IT. SNAP IT. SOLVED.", style: TextStyle(color: Colors.grey, letterSpacing: 3))),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 6, // Slightly larger to fit toggle
                        child: FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(30),
                            decoration: const BoxDecoration(color: Color(0xFF111111), borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_isLoginMode ? "Secure Login" : "Create Account", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                                const SizedBox(height: 20),
                                
                                // Role selection only visible during Login or Sign Up
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedRole,
                                      dropdownColor: const Color(0xFF222222),
                                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                      isExpanded: true,
                                      items: _roles.map((role) => DropdownMenuItem(value: role, child: Text(role, style: const TextStyle(color: Colors.white)))).toList(),
                                      onChanged: (val) => setState(() => _selectedRole = val!),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),

                                _buildTextField("College Email", Icons.alternate_email, _emailController),
                                const SizedBox(height: 15),
                                
                                // Password Field
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _isObscured,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: "Password",
                                    labelStyle: TextStyle(color: Colors.grey[600]),
                                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                                    suffixIcon: IconButton(icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.white38), onPressed: () => setState(() => _isObscured = !_isObscured)),
                                    filled: true,
                                    fillColor: Colors.black,
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)),
                                  ),
                                ),
                                
                                const SizedBox(height: 25),
                                
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _processAuth,
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                    child: _isLoading 
                                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
                                        : Text(_isLoginMode ? "ENTER CAMPUS" : "REGISTER ACCOUNT"),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Center(
                                  child: TextButton(
                                    onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                                    child: RichText(
                                      text: TextSpan(
                                        text: _isLoginMode ? "New User? " : "Already have an account? ",
                                        style: const TextStyle(color: Colors.white54),
                                        children: [
                                          TextSpan(text: _isLoginMode ? "Sign Up" : "Login", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.black, 
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white)), 
      ),
    );
  }
}