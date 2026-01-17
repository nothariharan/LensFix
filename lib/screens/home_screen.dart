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
import 'package:lens_fix/screens/history_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart'; 
import 'package:lens_fix/services/database_service.dart';
import 'package:geolocator/geolocator.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showXpNotification = false;
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  // --- TOP SNACKBAR HELPER ---
  void _showTopSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100, // Positions it at the top
          left: 20,
          right: 20,
        ),
      ),
    );
  }

  void _handleUpvote(String docId, Map<String, dynamic> data) async {
    try {
      Position pos = await Geolocator.getCurrentPosition();
      await DatabaseService().upvoteIssue(docId, pos);
      if (mounted) {
        Navigator.pop(context);
        _showTopSnackBar("Issue verified and upvoted!", Colors.greenAccent);
      }
    } catch (e) {
      if (mounted) {
        _showTopSnackBar(e.toString().replaceAll("Exception: ", ""), Colors.redAccent);
      }
    }
  }

  Future<void> _openCamera() async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => const CameraScreen())
    );

    if (result == true) {
      _triggerXpNotification();
    }
  }

  void _triggerXpNotification() {
    setState(() => _showXpNotification = true);
    Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showXpNotification = false);
    });
  }

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

  void _showIssueDetails(BuildContext context, String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Required for custom height
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(
            color: Color(0xFF111111), 
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: SafeArea( // FIX: Prevents overlap with Android Nav Bar
            child: Column(
              mainAxisSize: MainAxisSize.min, // Shrink to fit content
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(data['title'] ?? "Issue", style: GoogleFonts.bebasNeue(fontSize: 28, color: Colors.white))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.purple.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                      child: Text("${data['upvotes'] ?? 0} UPVOTES", style: const TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                
                Container(
                  height: 250, // Fixed image height
                  width: double.infinity,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: data['imageBase64'] != null
                        ? Image.memory(base64Decode(data['imageBase64']), fit: BoxFit.cover, gaplessPlayback: true)
                        : const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                  ),
                ),
                
                const SizedBox(height: 20),
                Text(data['description'] ?? "No description.", style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 30),

                // UPVOTE BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleUpvote(docId, data),
                    icon: const Icon(Icons.thumb_up_alt_outlined, color: Colors.black),
                    label: const Text("VERIFY & UPVOTE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
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
                      width: 50, height: 50,
                      child: GestureDetector(
                        onTap: () => _showIssueDetails(context, doc.id, data),
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
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.lens_fix'),
                  MarkerLayer(markers: markers),
                ],
              );
            },
          ),

          Positioned(
            top: 50, right: 20,
            child: GestureDetector(
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
                        return CircleAvatar(radius: 20, backgroundColor: Colors.black, backgroundImage: MemoryImage(base64Decode(data['profileImageBase64'])));
                      }
                    }
                    return const CircleAvatar(radius: 20, backgroundColor: Colors.black, child: Icon(Icons.person, color: Colors.white));
                  },
                ),
              ),
            ),
          ),

          if (_showXpNotification)
            Positioned(
              top: 58, right: 80, 
              child: FadeInRight( 
                duration: const Duration(milliseconds: 500),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.9), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.yellowAccent, width: 1.5), boxShadow: [BoxShadow(color: Colors.yellowAccent.withOpacity(0.3), blurRadius: 10)]),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.bolt, color: Colors.yellowAccent, size: 16),
                      SizedBox(width: 5),
                      Text("+50 XP", style: TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 80,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewPadding.bottom + 20, 
                left: 20, right: 20
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.9), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white24)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.history, color: Colors.white70, size: 28), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      height: 70, width: 70,
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey[300]!, width: 1), boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)]),
                      child: IconButton(icon: const Icon(Icons.camera_alt, color: Colors.black, size: 32), onPressed: _openCamera),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.emoji_events_outlined, color: Colors.white70, size: 28), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}