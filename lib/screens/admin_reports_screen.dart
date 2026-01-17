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

  int _sortStatus(String status, bool isUrgent) {
    if (isUrgent && status != 'Resolved') return 0; 
    if (status == 'Pending') return 1;
    return 2; 
  }

  void _showAdminActions(String docId, Map<String, dynamic> data) {
    bool isUrgent = data['isUrgent'] == true;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(color: Color(0xFF050510), borderRadius: BorderRadius.vertical(top: Radius.circular(30)), border: Border(top: BorderSide(color: Colors.cyanAccent, width: 2))),
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text("ADMIN ACTIONS", style: GoogleFonts.bebasNeue(color: Colors.cyanAccent, fontSize: 28, letterSpacing: 2)),
            const SizedBox(height: 5),
            Text("Location: ${data['building'] ?? 'Campus'} (Floor: ${data['floor'] ?? 'N/A'})", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            if (data['status'] != 'Resolved') ...[_buildActionTile(Icons.check_circle, "MARK RESOLVED", Colors.greenAccent, () { Navigator.pop(ctx); _dbService.resolveIssue(docId); }), const SizedBox(height: 10)],
            _buildActionTile(isUrgent ? Icons.notifications_off : Icons.notification_important, isUrgent ? "UNMARK URGENT" : "MARK URGENT", Colors.orangeAccent, () { Navigator.pop(ctx); _dbService.toggleUrgentStatus(docId, isUrgent); }),
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.white12)),
            _buildActionTile(Icons.delete_forever, "DELETE RECORD", Colors.redAccent, () { Navigator.pop(ctx); _dbService.deleteIssue(docId); }, isDestructive: true),
          ]),
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String label, Color color, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(onTap: onTap, tileColor: isDestructive ? Colors.redAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withOpacity(0.3))), leading: Icon(icon, color: color), title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1)), trailing: Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 14));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      appBar: AppBar(title: Text("ALL REPORTS", style: GoogleFonts.bebasNeue(letterSpacing: 2, color: Colors.white)), centerTitle: true, backgroundColor: Colors.transparent, leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context))),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('issues').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          var docs = snapshot.data!.docs;
          docs.sort((a, b) {
            var aData = a.data() as Map<String, dynamic>;
            var bData = b.data() as Map<String, dynamic>;
            return _sortStatus(aData['status'], aData['isUrgent'] == true).compareTo(_sortStatus(bData['status'], bData['isUrgent'] == true));
          });
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewPadding.bottom + 20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              bool isUrgent = data['isUrgent'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: const Color(0xFF12121F), borderRadius: BorderRadius.circular(15), border: Border.all(color: isUrgent ? Colors.redAccent : Colors.white10)),
                child: ListTile(
                  onTap: () => _showAdminActions(docs[index].id, data),
                  leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: data['imageBase64'] != null ? Image.memory(base64Decode(data['imageBase64']), width: 50, height: 50, fit: BoxFit.cover) : Container(width: 50, height: 50, color: Colors.grey[800], child: const Icon(Icons.image, size: 20))),
                  title: Text(data['title'] ?? "Issue", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text("${data['building'] ?? 'Campus'} • Floor: ${data['floor'] ?? 'N/A'}", style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  trailing: const Icon(Icons.more_vert, color: Colors.white54),
                ),
              );
            },
          );
        },
      ),
    );
  }
}