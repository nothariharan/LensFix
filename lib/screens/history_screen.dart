import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black, // NOIR THEME
      appBar: AppBar(
        title: Text("MY REPORTS", style: GoogleFonts.bebasNeue(letterSpacing: 2, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: uid == null 
          ? const Center(child: Text("Please Login", style: TextStyle(color: Colors.white)))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('issues')
                  .where('reportedBy', isEqualTo: uid) // Dynamic User Filter
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                
                // 1. Loading State
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                // 2. Empty State
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 50, color: Colors.grey[800]),
                        const SizedBox(height: 15),
                        const Text("No reports yet.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // 3. Separate Data into Sections
                var docs = snapshot.data!.docs;
                var completed = docs.where((doc) => doc['status'] == 'Resolved').toList();
                var inProgress = docs.where((doc) => doc['status'] != 'Resolved').toList();

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // COMPLETED SECTION
                    if (completed.isNotEmpty) ...[
                      _buildSectionTitle("COMPLETED"),
                      ...completed.map((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        return _buildHistoryCard(
                          data['title'] ?? "Issue",
                          data['category'] ?? "General", // Using Category as sub-text
                          _formatTimestamp(data['timestamp']),
                          Icons.check_circle,
                          Colors.greenAccent,
                        );
                      }),
                      const SizedBox(height: 30),
                    ],

                    // IN PROGRESS SECTION
                    if (inProgress.isNotEmpty) ...[
                      _buildSectionTitle("IN PROGRESS"),
                      ...inProgress.map((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        return _buildHistoryCard(
                          data['title'] ?? "Issue",
                          data['category'] ?? "General",
                          _formatTimestamp(data['timestamp']),
                          Icons.pending,
                          Colors.orangeAccent,
                        );
                      }),
                    ],
                  ],
                );
              },
            ),
    );
  }

  // --- HELPER: Simple Relative Time Formatter ---
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Just now";
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
    if (diff.inHours < 24) return "${diff.inHours} hrs ago";
    return "${diff.inDays} days ago";
  }

  // --- YOUR ORIGINAL UI WIDGETS (UNCHANGED) ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Text(
        title,
        style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Widget _buildHistoryCard(String title, String location, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111), // Matte Dark Grey
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(location, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text(time, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}