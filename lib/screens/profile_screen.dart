import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lens_fix/screens/login_screen.dart';
import 'package:lens_fix/screens/history_screen.dart'; 
import 'package:lens_fix/services/database_service.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  final DatabaseService _dbService = DatabaseService();

  Future<void> _pickAndSaveImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 30);
    if (pickedFile != null) {
      String base64 = await _dbService.convertImageToBase64(File(pickedFile.path));
      await _dbService.updateUserProfile(imageBase64: base64);
    }
  }

  void _editName(String currentName) {
    TextEditingController nameCtrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Edit Name", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "Enter name", hintStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                await _dbService.updateUserProfile(name: nameCtrl.text.trim());
                if(mounted) Navigator.pop(context);
              }
            }, 
            child: const Text("Save", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.settings, color: Colors.white54), onPressed: () {})],
      ),
      
      body: uid == null 
          ? const Center(child: Text("Please Login"))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, snapshot) {
                
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));

                var data = snapshot.data!.data() as Map<String, dynamic>?;
                int xp = data?['xp'] ?? 0;
                String email = data?['email'] ?? "Student";
                String displayName = data?['displayName'] ?? email.split('@')[0]; 
                String? dbImage = data?['profileImageBase64'];
                String role = data?['role'] ?? 'student'; // Get Role
                
                int level = (xp / 500).floor() + 1;
                bool isHelper = role.toLowerCase() == 'helper';

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // AVATAR
                      GestureDetector(
                        onTap: _pickAndSaveImage,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(width: 130, height: 130, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.15), blurRadius: 30, spreadRadius: 10)])),
                            Container(
                              padding: const EdgeInsets.all(4), 
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                              child: CircleAvatar(
                                radius: 60, backgroundColor: const Color(0xFF111111),
                                backgroundImage: dbImage != null ? MemoryImage(base64Decode(dbImage)) : null,
                                child: dbImage == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 5)]),
                                child: Text("LVL $level", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                              ),
                            ),
                            Positioned(
                              right: 0, top: 0,
                              child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.edit, size: 14, color: Colors.black)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      
                      GestureDetector(
                        onTap: () => _editName(displayName),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(displayName, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white)),
                            const SizedBox(width: 8),
                            const Icon(Icons.edit, color: Colors.white24, size: 20),
                          ],
                        ),
                      ),
                      
                      Text(isHelper ? "Maintenance Staff" : "Campus Guardian", style: GoogleFonts.outfit(fontSize: 16, color: Colors.orangeAccent, letterSpacing: 1, fontWeight: FontWeight.bold)), 

                      const SizedBox(height: 40),

                      // STATS ROW
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _buildStatCard("XP EARNED", "$xp", Colors.amberAccent),
                            const SizedBox(width: 15),
                            
                            // DYNAMIC COUNT (Reported vs Resolved)
                            FutureBuilder<AggregateQuerySnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('issues')
                                  .where(isHelper ? 'resolvedBy' : 'reportedBy', isEqualTo: uid) // Logic Switch
                                  .count()
                                  .get(),
                              builder: (context, countSnap) {
                                String count = countSnap.hasData ? "${countSnap.data!.count}" : "-";
                                return _buildStatCard(
                                  isHelper ? "REPORTS FIXED" : "ISSUES REPORTED", // Label Switch
                                  count, 
                                  Colors.greenAccent, 
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                                );
                              }
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // RANK
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: FutureBuilder<AggregateQuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .where('xp', isGreaterThan: xp)
                              .count()
                              .get(),
                          builder: (context, rankSnap) {
                            String rankDisplay = "#--";
                            
                            if (rankSnap.hasData && rankSnap.data != null) {
                              // FIX: Use '?? 0' to handle if count is null
                              int count = rankSnap.data?.count ?? 0;
                              int myRank = count + 1; 
                              rankDisplay = "#$myRank";
                            }
                            
                            return _buildWideStatCard("CURRENT RANK", rankDisplay, Colors.white);
                          }
                        ),
                      ),

                      const SizedBox(height: 50),

                      // LOGOUT
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: OutlinedButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (!mounted) return;
                            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                          },
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), backgroundColor: Colors.redAccent.withOpacity(0.05)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.logout, color: Colors.redAccent), SizedBox(width: 10), Text("LOGOUT", style: TextStyle(color: Colors.redAccent, letterSpacing: 1, fontWeight: FontWeight.bold))]),
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(20), border: Border.all(color: onTap != null ? color.withOpacity(0.5) : Colors.white12), boxShadow: onTap != null ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)] : []),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)), if (onTap != null) Icon(Icons.arrow_forward_ios, size: 12, color: color)]),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
          ]),
        ),
      ),
    );
  }

  Widget _buildWideStatCard(String label, String value, Color color) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)), Text(value, style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold))]),
    );
  }
}