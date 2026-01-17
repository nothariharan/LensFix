import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lens_fix/services/database_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final DatabaseService _dbService = DatabaseService();

  // Sort: Urgent -> Pending -> Resolved
  int _sortStatus(String status, bool isUrgent) {
    if (isUrgent && status != 'Resolved') return 0; // Urgent & Active
    if (status == 'Pending') return 1;
    return 2; // Resolved
  }

  void _showAdminActions(String docId, Map<String, dynamic> data) {
    bool isUrgent = data['isUrgent'] == true;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: Color(0xFF050510),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(top: BorderSide(color: Colors.cyanAccent)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ADMIN ACTIONS", style: GoogleFonts.bebasNeue(color: Colors.cyanAccent, fontSize: 24, letterSpacing: 2)),
            const SizedBox(height: 20),
            
            // 1. Mark Resolved
            if (data['status'] != 'Resolved')
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.greenAccent),
                title: const Text("MARK RESOLVED", style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.pop(ctx); _dbService.resolveIssue(docId); },
              ),

            // 2. Toggle Urgent
            ListTile(
              leading: Icon(isUrgent ? Icons.notifications_off : Icons.notification_important, color: Colors.orangeAccent),
              title: Text(isUrgent ? "UNMARK URGENT" : "MARK URGENT", style: const TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(ctx); _dbService.toggleUrgentStatus(docId, isUrgent); },
            ),

            const Divider(color: Colors.white24),

            // 3. Delete
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text("DELETE RECORD", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () { Navigator.pop(ctx); _dbService.deleteIssue(docId); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      appBar: AppBar(
        title: Text("ALL REPORTS", style: GoogleFonts.bebasNeue(letterSpacing: 2, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('issues').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));

          var docs = snapshot.data!.docs;
          // Custom Sort
          docs.sort((a, b) {
            var aData = a.data() as Map<String, dynamic>;
            var bData = b.data() as Map<String, dynamic>;
            return _sortStatus(aData['status'], aData['isUrgent'] == true)
                .compareTo(_sortStatus(bData['status'], bData['isUrgent'] == true));
          });

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = docs[index];
              var data = doc.data() as Map<String, dynamic>;
              bool isUrgent = data['isUrgent'] == true;
              bool isEscalated = data['isEscalation'] == true;

              return ListTile(
                onTap: () => _showAdminActions(doc.id, data),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                tileColor: const Color(0xFF12121F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isUrgent ? Colors.redAccent : Colors.white10)),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: data['imageBase64'] != null 
                    ? Image.memory(base64Decode(data['imageBase64']), width: 50, height: 50, fit: BoxFit.cover)
                    : Container(width: 50, height: 50, color: Colors.grey[800], child: const Icon(Icons.image, size: 20)),
                ),
                title: Text(data['title'] ?? "Issue", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Row(
                  children: [
                    if (isUrgent) const Text("🚨 URGENT  ", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    if (isEscalated) const Text("⚠️ ESCALATED  ", style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(data['status'] ?? "Pending", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
                trailing: const Icon(Icons.more_vert, color: Colors.white54),
              );
            },
          );
        },
      ),
    );
  }
}