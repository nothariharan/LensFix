import 'dart:math'; 
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart';      
import 'package:lens_fix/screens/camera_screen.dart';
import 'package:lens_fix/screens/leaderboard_screen.dart';
import 'package:lens_fix/screens/profile_screen.dart';
import 'package:lens_fix/screens/history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Marker> _markers = [
    Marker(
      point: const LatLng(13.5562, 80.0265),
      width: 50, height: 50,
      child: _buildPinStatic(Colors.redAccent, Icons.electrical_services),
    ),
    Marker(
      point: const LatLng(13.5555, 80.0255),
      width: 40, height: 40,
      child: _buildPinStatic(Colors.greenAccent, Icons.check),
    ),
  ];

  Future<void> _openCamera() async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => const CameraScreen())
    );
    if (result != null && result is Map) {
       _addNewIssueMarker();
    }
  }

  void _addNewIssueMarker() {
    setState(() {
      final random = Random();
      final double latOffset = (random.nextDouble() - 0.5) * 0.001;
      final double lngOffset = (random.nextDouble() - 0.5) * 0.001;
      _markers.add(
        Marker(
          point: LatLng(13.5560 + latOffset, 80.0260 + lngOffset),
          width: 60, height: 60,
          child: _buildPinStatic(Colors.orangeAccent, Icons.warning_amber_rounded),
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: const [Icon(Icons.check_circle, color: Colors.black), SizedBox(width: 10), Text("Issue Reported! (+50 XP)", style: TextStyle(color: Colors.black))]),
        backgroundColor: Colors.white, // NOIR THEME: White SnackBar
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static Widget _buildPinStatic(Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
      ),
      child: Icon(icon, color: Colors.black, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // LAYER 1: MAP
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(13.5560, 80.0260), 
              initialZoom: 16.5,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // Consider finding a dark mode map tile server for full effect
                userAgentPackageName: 'com.example.lens_fix',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),

          // LAYER 2: PROFILE ICON
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

          // LAYER 3: DOCK
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9), // Pure Black Dock
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.history, color: Colors.white70, size: 28), onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                  },),
                  
                  // CAMERA BUTTON (The White Pearl)
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      height: 70, width: 70,
                      decoration: BoxDecoration(
                        color: Colors.white, // NOIR THEME: White Circle
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                        boxShadow: [
                          BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.black, size: 32), // Black Icon
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