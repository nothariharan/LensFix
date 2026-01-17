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
  // --- HELPERS ---
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return Colors.cyanAccent;
      case 'helper': return Colors.orangeAccent;
      default: return Colors.white54; // Student
    }
  }

  void _deleteUser(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text("DELETE USER?", style: TextStyle(color: Colors.redAccent)),
        content: const Text("This will permanently remove their records. They won't be able to log in properly.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('users').doc(docId).delete();
              if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User Deleted"), backgroundColor: Colors.red));
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _addUser() {
    TextEditingController emailCtrl = TextEditingController();
    String selectedRole = 'Student';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text("ADD NEW USER", style: TextStyle(color: Colors.cyanAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Email", labelStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24))),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedRole,
              dropdownColor: const Color(0xFF2D2D40),
              style: const TextStyle(color: Colors.white),
              items: ['Student', 'Helper', 'Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) => selectedRole = val!,
              decoration: const InputDecoration(labelText: "Role", labelStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24))),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              if (emailCtrl.text.isNotEmpty) {
                // Create a placeholder doc. The user must Sign Up with this email to activate Auth.
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
            child: const Text("ADD TO DB", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510), // Cyberpunk Dark
      appBar: AppBar(
        title: Text("USER DATABASE", style: GoogleFonts.bebasNeue(letterSpacing: 2, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUser,
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('role').snapshots(), // Sort by role roughly groups them
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String role = data['role'] ?? 'student';
              String name = data['displayName'] ?? (data['email'] ?? "Unknown").split('@')[0];
              int xp = data['xp'] ?? 0;
              int level = (xp / 500).floor() + 1;

              return FadeInUp(
                delay: Duration(milliseconds: index * 50),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12121F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getRoleColor(role).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: _getRoleColor(role).withOpacity(0.2),
                        child: Text(name[0].toUpperCase(), style: TextStyle(color: _getRoleColor(role), fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 15),
                      
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(data['email'] ?? "No Email", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ),

                      // Stats & Role Badge
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: _getRoleColor(role), borderRadius: BorderRadius.circular(4)),
                            child: Text(role.toUpperCase(), style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 4),
                          Text("LVL $level • $xp XP", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                      
                      const SizedBox(width: 15),
                      
                      // Delete
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () => _deleteUser(doc.id),
                      ),
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
}