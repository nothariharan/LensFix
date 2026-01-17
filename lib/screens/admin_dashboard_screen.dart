import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lens_fix/screens/login_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510), // Deep Cyberpunk Blue-Black
      appBar: AppBar(
        title: Text("COMMAND CENTER", style: GoogleFonts.bebasNeue(letterSpacing: 3, color: Colors.cyanAccent)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. SYSTEM STATS ROW
            _buildSystemStats(),
            
            const SizedBox(height: 30),
            
            // 2. ESCALATIONS SECTION (The "Red Phone")
            Text("🚨 ESCALATED ISSUES", style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 10),
            _buildEscalationFeed(),

            const SizedBox(height: 30),

            // 3. LIVE ACTIVITY FEED
            Text("📡 LIVE NETWORK ACTIVITY", style: GoogleFonts.outfit(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 10),
            _buildActivityFeed(),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: SYSTEM STATS ---
  Widget _buildSystemStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('issues').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator(color: Colors.cyanAccent);
        
        var docs = snapshot.data!.docs;
        int total = docs.length;
        int resolved = docs.where((doc) => doc['status'] == 'Resolved').length;
        int pending = total - resolved;

        return Row(
          children: [
            _buildStatCard("TOTAL", total.toString(), Colors.blueGrey),
            const SizedBox(width: 15),
            _buildStatCard("ACTIVE", pending.toString(), Colors.orangeAccent),
            const SizedBox(width: 15),
            _buildStatCard("FIXED", resolved.toString(), Colors.greenAccent),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color, fontFamily: 'Courier')),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: ESCALATION FEED ---
  Widget _buildEscalationFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('issues')
          .where('isEscalation', isEqualTo: true)
          .where('status', isNotEqualTo: 'Resolved') // Only show active escalations
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text("ALL SYSTEMS NORMAL", style: TextStyle(color: Colors.grey, letterSpacing: 2))),
          );
        }

        return SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return FadeInRight(
                child: Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                          const SizedBox(width: 10),
                          Expanded(child: Text(data['title'] ?? "Critical Issue", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text("📍 ${data['category']}", style: const TextStyle(color: Colors.grey)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(5)),
                        child: const Text("REQUIRES ADMIN ACTION", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // --- WIDGET: ACTIVITY FEED ---
  Widget _buildActivityFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('issues').orderBy('timestamp', descending: true).limit(10).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            bool isResolved = data['status'] == 'Resolved';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF11111E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Icon(
                    isResolved ? Icons.check_circle : Icons.fiber_manual_record, 
                    color: isResolved ? Colors.greenAccent : Colors.orangeAccent, 
                    size: 14
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['title'] ?? "Log Entry", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text("${data['category']} • ${data['severity']}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(isResolved ? "RESOLVED" : "PENDING", style: TextStyle(color: isResolved ? Colors.greenAccent : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}