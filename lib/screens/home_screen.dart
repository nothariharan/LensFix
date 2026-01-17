import 'dart:convert'; 
import 'dart:math'; 
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart';      
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:lens_fix/screens/camera_screen.dart';
import 'package:lens_fix/screens/leaderboard_screen.dart';
import 'package:lens_fix/screens/profile_screen.dart';
import 'package:lens_fix/screens/history_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  Future<void> _openCamera() async {
    await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => const CameraScreen())
    );
  }

  // --- UPDATED: ICON SELECTOR ---
  IconData _getCategoryIcon(String category) {
    switch (category.trim()) {
      case 'Electrical': return Icons.electrical_services;
      case 'Plumbing': return Icons.plumbing;
      case 'Furniture': return Icons.chair; // or Icons.weekend
      case 'IT': return Icons.computer;
      case 'Structural': return Icons.foundation; // or Icons.house
      case 'Cleaning': return Icons.cleaning_services;
      case 'Security': return Icons.security;
      default: return Icons.report_problem; // 'Other' or fallback
    }
  }

  // --- UPDATED: MARKER BUILDER ---
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
      child: Icon(
        _getCategoryIcon(category), // Dynamic Icon
        color: Colors.black, 
        size: 20
      ),
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
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: data['imageBase64'] != null
                        ? Image.memory(
                            base64Decode(data['imageBase64']), 
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          )
                        : const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(10)
                    ),
                    child: Text("SEVERITY: ${data['severity']}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  // SHOW CATEGORY BADGE
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white10
                    ),
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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('issues').snapshots(),
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
                      width: 50, 
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _showIssueDetails(context, data),
                        // Pass Category AND Severity
                        child: _buildPinStatic(data['severity'] ?? 'Low', data['category'] ?? 'Other'),
                      ),
                    ),
                  );
                }
              }

              return FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(13.5560, 80.0260), 
                  initialZoom: 16.5,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.lens_fix',
                  ),
                  MarkerLayer(markers: markers),
                ],
              );
            },
          ),

          Positioned(
            top: 50, right: 20,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                color: Colors.black,
              ),
              child: IconButton(
                icon: const Icon(Icons.person, color: Colors.white),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                },
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.history, color: Colors.white70, size: 28), onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                  },),
                  
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      height: 70, width: 70,
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                        boxShadow: [
                          BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.black, size: 32), 
                        onPressed: _openCamera,
                      ),
                    ),
                  ),

                  IconButton(icon: const Icon(Icons.emoji_events_outlined, color: Colors.white70, size: 28), onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
                  },),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}