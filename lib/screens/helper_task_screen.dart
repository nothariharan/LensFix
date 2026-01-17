import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lens_fix/services/database_service.dart';

class HelperTaskScreen extends StatefulWidget {
  const HelperTaskScreen({super.key});

  @override
  State<HelperTaskScreen> createState() => _HelperTaskScreenState();
}

class _HelperTaskScreenState extends State<HelperTaskScreen> {
  final DatabaseService _dbService = DatabaseService();

  void _showTaskDetails(String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: SafeArea( // FIX: UI OVERLAP
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              
              // Title with Escalation Tag
              Row(
                children: [
                  Expanded(child: Text(data['title'] ?? "Issue", style: GoogleFonts.bebasNeue(fontSize: 28, color: Colors.white))),
                  if (data['isEscalation'] == true) 
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                      child: const Text("ESCALATED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                    )
                ],
              ),
              const SizedBox(height: 15),
              
              // Image
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: data['imageBase64'] != null
                        ? Image.memory(base64Decode(data['imageBase64']), fit: BoxFit.cover)
                        : const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              Text("SUGGESTED FIX:", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(data['fix'] ?? "None", style: const TextStyle(color: Colors.white70)),
              
              const SizedBox(height: 30),
              
              // RESOLVE BUTTON (CRASH FIX)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // 1. Close the BottomSheet FIRST
                    Navigator.pop(ctx); 
                    
                    // 2. Run Database logic
                    await _dbService.resolveIssue(docId); 
                    
                    // 3. Show SnackBar using the Screen's context (if still mounted)
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Issue Resolved! +100 XP"), backgroundColor: Colors.green)
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  icon: const Icon(Icons.check_circle, color: Colors.black),
                  label: const Text("MARK AS RESOLVED", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("PENDING TASKS", style: GoogleFonts.bebasNeue(letterSpacing: 2, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('issues').where('status', isEqualTo: 'Pending').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
          
          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.check_circle_outline, size: 60, color: Colors.grey), SizedBox(height: 10), Text("All Clean! No issues.", style: TextStyle(color: Colors.grey))]));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              bool isEscalation = data['isEscalation'] == true;

              return GestureDetector(
                onTap: () => _showTaskDetails(doc.id, data),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isEscalation ? Colors.red : Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.warning, color: Colors.redAccent),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(data['title'] ?? "Issue", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                if (isEscalation) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                    child: const Text("ESCALATED", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                                  )
                                ]
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(data['category'] ?? "General", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
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