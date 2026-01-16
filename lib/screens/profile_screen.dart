import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lens_fix/screens/login_screen.dart';
import 'package:lens_fix/screens/history_screen.dart'; // Import History Screen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() { _profileImage = File(pickedFile.path); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // NOIR THEME
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.settings, color: Colors.white54), onPressed: () {})
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // AVATAR WITH GLOW
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // The Glow Container
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.15), // Subtle white glow
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  // The Ring & Image
                  Container(
                    padding: const EdgeInsets.all(4), // Spacing between ring and image
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2), // White Ring
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFF111111),
                      backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                      child: _profileImage == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
                    ),
                  ),
                  // The Level Badge
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white, // White Badge
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 5)],
                      ),
                      child: const Text("LVL 5", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                  ),
                  // Camera Icon hint
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 14, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text("HARIHARAN", style: GoogleFonts.bebasNeue(fontSize: 36, letterSpacing: 2, color: Colors.white)),
            Text("Campus Guardian", style: GoogleFonts.outfit(fontSize: 16, color: Colors.orangeAccent, letterSpacing: 1, fontWeight: FontWeight.bold)), // Orange Title

            const SizedBox(height: 40),

            // STATS ROW
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildStatCard(
                    "XP EARNED", 
                    "1,200", 
                    Colors.amberAccent, // Yellow for XP
                  ),
                  const SizedBox(width: 15),
                  _buildStatCard(
                    "ISSUES FIXED", 
                    "12", 
                    Colors.greenAccent, // Green for Issues
                    // Navigate to History when tapped
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 15),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildWideStatCard("CURRENT RANK", "#1", Colors.white),
            ),

            const SizedBox(height: 50),

            // LOGOUT BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1.5), // Red Border
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.redAccent.withOpacity(0.05), // Slight red tint background
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.logout, color: Colors.redAccent), // Red Icon
                    SizedBox(width: 10),
                    Text("LOGOUT", style: TextStyle(color: Colors.redAccent, letterSpacing: 1, fontWeight: FontWeight.bold)), // Red Text
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated Helper: Accepts onTap for interactivity
  Widget _buildStatCard(String label, String value, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: onTap != null ? color.withOpacity(0.5) : Colors.white12), // Highlight border if clickable
            boxShadow: onTap != null ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)] : [], // Highlight glow if clickable
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  if (onTap != null) Icon(Icons.arrow_forward_ios, size: 12, color: color), // Arrow hint if clickable
                ],
              ),
              const SizedBox(height: 10),
              Text(value, style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWideStatCard(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}