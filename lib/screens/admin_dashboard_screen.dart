import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lens_fix/screens/login_screen.dart';
import 'package:lens_fix/screens/admin_reports_screen.dart'; // We will create this
import 'package:lens_fix/screens/admin_user_database_screen.dart'; // We will create this
import 'package:lens_fix/screens/leaderboard_screen.dart';
import 'package:lens_fix/screens/admin_profile_screen.dart'; // We will create this
import 'package:lens_fix/services/database_service.dart';
import 'package:lens_fix/widgets/blinking_marker.dart'; // Reusing your blinking marker

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DatabaseService _dbService = DatabaseService();

  // --- MARKER HELPERS ---
  IconData _getCategoryIcon(String category) {
    switch (category.trim()) {
      case 'Electrical': return Icons.electrical_services;
      case 'Plumbing': return Icons.plumbing;
      case 'Furniture': return Icons.chair;
      case 'IT': return Icons.computer;
      case 'Structural': return Icons.foundation;
      case 'Cleaning': return Icons.cleaning_services;
      case 'Security': return Icons.security;
      default: return Icons.report_problem;
    }
  }

  Widget _buildPinDynamic(String status, String severity, String category) {
    Color color;
    if (status == 'Resolved') {
      color = const Color(0xFF00E676); // Bright Green
    } else {
      switch (severity.toLowerCase()) {
        case 'high': color = Colors.redAccent; break;
        case 'medium': color = Colors.orangeAccent; break;
        default: color = Colors.greenAccent; break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
      ),
      child: Icon(_getCategoryIcon(category), color: Colors.black, size: 20),
    );
  }

  // --- BOTTOM SHEET (ADMIN ACTIONS) ---
  void _showIssueDetails(String docId, Map<String, dynamic> data) {
    bool isUrgent = data['isUrgent'] == true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 600,
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(
            color: Color(0xFF050510), // Cyberpunk Dark Blue
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            border: Border(top: BorderSide(color: Colors.cyanAccent, width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(data['title'] ?? "Issue", style: GoogleFonts.bebasNeue(fontSize: 28, color: Colors.white))),
                  if (data['isEscalation'] == true)
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)), child: const Text("ESCALATED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10))),
                ],
              ),
              const SizedBox(height: 10),

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
              Text(data['description'] ?? "No description.", style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 30),

              // ADMIN ACTION BUTTONS
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _dbService.toggleUrgentStatus(docId, isUrgent);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isUrgent ? Colors.grey[800] : Colors.redAccent, // Toggle Color
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    side: BorderSide(color: isUrgent ? Colors.white24 : Colors.redAccent),
                  ),
                  icon: Icon(isUrgent ? Icons.notifications_off : Icons.notification_important),
                  label: Text(isUrgent ? "UNMARK URGENT" : "MARK AS URGENT", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
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
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // LAYER 1: MAP
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('issues').snapshots(),
            builder: (context, snapshot) {
              List<Marker> markers = [];
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  GeoPoint? geo = data['location'];
                  if (geo == null) continue;

                  bool isUrgent = data['isUrgent'] == true;

                  markers.add(
                    Marker(
                      point: LatLng(geo.latitude, geo.longitude),
                      width: isUrgent ? 80 : 50,
                      height: isUrgent ? 80 : 50,
                      child: GestureDetector(
                        onTap: () => _showIssueDetails(doc.id, data),
                        child: BlinkingMarker( // Reusing your BlinkingMarker
                          isUrgent: isUrgent,
                          child: _buildPinDynamic(data['status'] ?? 'Pending', data['severity'] ?? 'Low', data['category'] ?? 'Other'),
                        ),
                      ),
                    ),
                  );
                }
              }
              return FlutterMap(
                options: MapOptions(initialCenter: const LatLng(13.5550, 80.0260), initialZoom: 16.5),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.lens_fix'),
                  MarkerLayer(markers: markers),
                ],
              );
            },
          ),

          // LAYER 2: ADMIN HEADER
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent, // Cyberpunk Cyan for Admin
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.4), blurRadius: 10)]
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.admin_panel_settings, color: Colors.black, size: 18),
                        SizedBox(width: 8),
                        Text("ADMIN MODE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ],
                    ),
                  ),
                  
                  // Admin Profile
                  GestureDetector(
                    // We will create AdminProfileScreen in Phase 3
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfileScreen())), 
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.cyanAccent, width: 2), color: Colors.black),
                      child: const CircleAvatar(radius: 20, backgroundColor: Colors.black, child: Icon(Icons.person, color: Colors.cyanAccent)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // LAYER 3: ADMIN DOCK
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF050510).withOpacity(0.9), // Dark Blue
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)), // Cyan Border
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // REPORTS LIST
                  IconButton(
                    icon: const Icon(Icons.assignment, color: Colors.white70, size: 28),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReportsScreen())), // Phase 3
                  ),
                  
                  // DATABASE BUTTON (The Centerpiece)
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      height: 70, width: 70,
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.4), blurRadius: 20)],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.storage, color: Colors.black, size: 32), // Database Icon
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUserDatabaseScreen())), // Phase 3
                      ),
                    ),
                  ),

                  // LEADERBOARD
                  IconButton(
                    icon: const Icon(Icons.emoji_events_outlined, color: Colors.white70, size: 28),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}