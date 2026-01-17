import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class AdminUserDatabaseScreen extends StatefulWidget {
  const AdminUserDatabaseScreen({super.key});

  @override
  State<AdminUserDatabaseScreen> createState() => _AdminUserDatabaseScreenState();
}

class _AdminUserDatabaseScreenState extends State<AdminUserDatabaseScreen> {
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return Colors.cyanAccent;
      case 'helper': return Colors.orangeAccent;
      default: return Colors.purpleAccent; // Student color
    }
  }

  // --- THE "ADD USER" PANEL ---
  void _addUser() {
    TextEditingController emailCtrl = TextEditingController();
    String selectedRole = 'Student';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 30, right: 30, top: 30,
          // FIX: Handle keyboard AND Nav Bar overlap
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 30 
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF0F0F1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: Colors.cyanAccent, width: 1.5)),
        ),
        child: SafeArea( // FIX: Wrap in SafeArea
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("GRANT ACCESS", style: GoogleFonts.bebasNeue(fontSize: 32, color: Colors.cyanAccent, letterSpacing: 2)),
              const SizedBox(height: 5),
              const Text("Pre-authorize a new user. They must Sign Up with this email to activate.", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 25),
              
              TextField(
                controller: emailCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.alternate_email, color: Colors.cyanAccent),
                  hintText: "University Email",
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true, fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedRole,
                    dropdownColor: const Color(0xFF1E1E2C),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    items: ['Student', 'Helper', 'Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) => setState(() => selectedRole = val!),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (emailCtrl.text.isNotEmpty) {
                      await FirebaseFirestore.instance.collection('users').add({
                        'email': emailCtrl.text.trim(),
                        'role': selectedRole.toLowerCase(),
                        'displayName': emailCtrl.text.split('@')[0],
                        'xp': 0,
                        'reports': 0, 
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      if(mounted) Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text("AUTHORIZE USER", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // REPLACE the existing _deleteUser function with this:

  void _deleteUser(String docId, String name) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => Container(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: anim1,
          child: AlertDialog(
            backgroundColor: const Color(0xFF0F0F1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            title: Column(
              children: [
                const Icon(Icons.gpp_maybe_rounded, color: Colors.redAccent, size: 50),
                const SizedBox(height: 15),
                Text("REVOKE ACCESS", 
                  style: GoogleFonts.bebasNeue(color: Colors.redAccent, fontSize: 28, letterSpacing: 2)),
              ],
            ),
            content: Text(
              "Are you sure you want to terminate access for $name? This action will wipe their credentials from the secure database.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await FirebaseFirestore.instance.collection('users').doc(docId).delete();
                  if(mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Access Revoked"), backgroundColor: Colors.redAccent)
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("CONFIRM TERMINATION"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      appBar: AppBar(
        title: Text("USER DATABASE", style: GoogleFonts.bebasNeue(letterSpacing: 2, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addUser, backgroundColor: Colors.cyanAccent, child: const Icon(Icons.person_add, color: Colors.black)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('role').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), 
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              
              // FIX: Fallback values for missing data so it doesn't crash
              String role = data['role'] ?? 'student'; 
              String email = data['email'] ?? "Unknown";
              String name = data['displayName'] ?? (email != "Unknown" ? email.split('@')[0] : "User");
              int xp = data['xp'] ?? 0;
              int activityCount = data['reports'] ?? 0; 
              String activityLabel = role.toLowerCase() == 'helper' ? "Fixed" : "Reports";

              return FadeInUp(
                duration: const Duration(milliseconds: 300),
                delay: Duration(milliseconds: index * 50),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12121F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _getRoleColor(role).withOpacity(0.3)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 24, backgroundColor: _getRoleColor(role).withOpacity(0.2), child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: _getRoleColor(role), fontWeight: FontWeight.bold, fontSize: 18))),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(email, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _buildBadge(role.toUpperCase(), _getRoleColor(role)),
                                const SizedBox(width: 8),
                                Text("$xp XP • $activityCount $activityLabel", style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.white24), onPressed: () => _deleteUser(doc.id, name)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)), child: Text(text, style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)));
  }
}