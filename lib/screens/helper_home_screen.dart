import 'dart:async'; 
import 'dart:convert'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart';      
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:lens_fix/screens/camera_screen.dart';
import 'package:lens_fix/screens/leaderboard_screen.dart';
import 'package:lens_fix/screens/profile_screen.dart';
import 'package:lens_fix/screens/helper_task_screen.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart'; 

class HelperHomeScreen extends StatefulWidget {
  const HelperHomeScreen({super.key});

  @override
  State<HelperHomeScreen> createState() => _HelperHomeScreenState();
}

class _HelperHomeScreenState extends State<HelperHomeScreen> {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  // --- MARKER HELPERS (Same as Student App) ---
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

  // Same visual style as Student App (Severity Colors)
  Widget _buildPinStatic(String severity, String category) {
    Color color = Colors.greenAccent; 
    if (severity.toLowerCase() == 'medium') color = Colors.orangeAccent;
    if (severity.toLowerCase() == 'high') color = Colors.redAccent;

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

  void _showIssueDetails(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 550, 
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(
            color: Color(0xFF111111), 
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(data['title'] ?? "Unknown Issue", style: GoogleFonts.bebasNeue(fontSize: 28, color: Colors.white)),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(10)),
                    child: Text("SEVERITY: ${data['severity']}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(10), color: Colors.white10),
                    child: Text(data['category'] ?? "Other", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(data['description'] ?? "No description provided.", style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
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
          // LAYER 1: MAP (Shows ONLY Pending issues)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('issues')
                .where('status', isNotEqualTo: 'Resolved') // <--- HIDE RESOLVED ISSUES
                .snapshots(),
            builder: (context, snapshot) {
              List<Marker> markers = [];
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  GeoPoint? geo = data['location'];
                  if (geo == null) continue;

                  markers.add(
                    Marker(
                      point: LatLng(geo.latitude, geo.longitude),
                      width: 50, height: 50,
                      child: GestureDetector(
                        onTap: () => _showIssueDetails(context, data),
                        child: _buildPinStatic(data['severity'] ?? 'Low', data['category'] ?? 'Other'),
                      ),
                    ),
                  );
                }
              }

              return FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(13.5550, 80.0260), 
                  initialZoom: 16.5,
                ),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.lens_fix'),
                  MarkerLayer(markers: markers),
                ],
              );
            },
          ),

          // LAYER 2: HELPER HEADER
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent, // Orange for Helpers
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 10)]
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.build_circle, color: Colors.black, size: 18),
                        SizedBox(width: 8),
                        Text("HELPER MODE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ],
                    ),
                  ),
                  
                  // Profile Icon
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), color: Colors.black),
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: uid != null ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots() : null,
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.exists) {
                            var data = snapshot.data!.data() as Map<String, dynamic>;
                            if (data['profileImageBase64'] != null) {
                              return CircleAvatar(radius: 20, backgroundImage: MemoryImage(base64Decode(data['profileImageBase64'])));
                            }
                          }
                          return const CircleAvatar(radius: 20, backgroundColor: Colors.black, child: Icon(Icons.person, color: Colors.white));
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // LAYER 3: DOCK
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)), // Orange Border
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // TASKS LIST (Navigates to Helper Task Screen)
                  IconButton(
                    icon: const Icon(Icons.assignment_turned_in, color: Colors.white70, size: 28), 
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HelperTaskScreen()));
                    },
                  ),
                  
                  // ESCALATE BUTTON (Navigates to Camera with Flag)
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      height: 70, width: 70,
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent, // Orange Button
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(color: Colors.orangeAccent.withOpacity(0.4), blurRadius: 20)],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add_a_photo, color: Colors.black, size: 32), 
                        onPressed: () {
                          // Opens Escalation Camera
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraScreen(isEscalation: true)));
                        },
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.emoji_events_outlined, color: Colors.white70, size: 28), 
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()))
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