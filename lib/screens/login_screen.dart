import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart'; 
import 'package:lens_fix/screens/home_screen.dart';
import 'package:lens_fix/services/auth_service.dart';
import 'package:lens_fix/services/database_service.dart'; 
import 'package:lens_fix/screens/helper_home_screen.dart';
import 'package:lens_fix/screens/admin_dashboard_screen.dart'; // <--- NEW IMPORT

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _dbService = DatabaseService(); 
  
  bool _isLoading = false;
  
  // ROLE STATE
  String _selectedRole = 'Student';
  final List<String> _roles = ['Student', 'Helper', 'Admin'];

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter Email & Password"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Authenticate
      await _authService.signIn(email, password);
      
      // 2. Sync Role to Database (Only creates new doc if user is new)
      await _dbService.ensureUserExists(_selectedRole);

      if (!mounted) return;
      
      // 3. Check Role & Route
      User? user = FirebaseAuth.instance.currentUser;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      String role = (userDoc.data() as Map<String, dynamic>)['role'] ?? 'student';

      if (!mounted) return;

      if (role.toLowerCase() == 'helper') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HelperHomeScreen())); // Go to Staff App
      } else if (role.toLowerCase() == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())); // Go to Admin App <--- NEW LOGIC
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen())); // Go to Student App
      }

    } on FirebaseAuthException catch (e) {
      String message = "Authentication Failed";
      if (e.code == 'user-not-found') message = "User not found. Contact Admin.";
      if (e.code == 'wrong-password') message = "Incorrect Password.";
      if (e.code == 'invalid-email') message = "Invalid Email Format.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                              color: Color(0xFF111111),
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Welcome Back", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                                const SizedBox(height: 20),
                                
                                // ROLE DROPDOWN
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedRole,
                                      dropdownColor: const Color(0xFF222222),
                                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                      isExpanded: true,
                                      items: _roles.map((String role) {
                                        return DropdownMenuItem<String>(
                                          value: role,
                                          child: Row(
                                            children: [
                                              Icon(
                                                role == 'Admin' ? Icons.security : (role == 'Helper' ? Icons.build : Icons.school),
                                                color: Colors.white70,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 10),
                                              Text(role, style: const TextStyle(color: Colors.white)),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedRole = newValue!;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),

                                _buildTextField("College Email", Icons.alternate_email, _emailController),
                                const SizedBox(height: 15),
                                _buildTextField("Password", Icons.lock_outline, _passwordController, isPassword: true),
                                
                                const SizedBox(height: 30),
                                
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: _isLoading 
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                      : const Text("ENTER CAMPUS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
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