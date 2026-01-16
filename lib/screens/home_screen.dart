import 'dart:math'; // For randomizing pin location slightly
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart';      
import 'package:lens_fix/screens/camera_screen.dart';
import 'package:lens_fix/screens/leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1. Dynamic List of Markers
  final List<Marker> _markers = [
    // Existing Hardcoded Markers (Demo Data)
    Marker(
      point: const LatLng(13.5562, 80.0265),
      width: 50,
      height: 50,
      child: _buildPinStatic(Colors.redAccent, Icons.electrical_services),
    ),
    Marker(
      point: const LatLng(13.5555, 80.0255),
      width: 40,
      height: 40,
      child: _buildPinStatic(Colors.greenAccent, Icons.check),
    ),
  ];

  // 2. Function to Open Camera and Handle Result
  Future<void> _openCamera() async {
    // Wait for the Camera Screen to return data
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => const CameraScreen())
    );

    // If we got data back (User hit "Submit")
    if (result != null && result is String) {
      _addNewIssueMarker(result);
    }
  }

  void _addNewIssueMarker(String description) {
    setState(() {
      // Create a slight offset so it doesn't overlap perfectly (Fake GPS)
      final random = Random();
      final double latOffset = (random.nextDouble() - 0.5) * 0.001;
      final double lngOffset = (random.nextDouble() - 0.5) * 0.001;

      _markers.add(
        Marker(
          point: LatLng(13.5560 + latOffset, 80.0260 + lngOffset),
          width: 60,
          height: 60,
          child: _buildPinStatic(Colors.orangeAccent, Icons.warning_amber_rounded),
        ),
      );
    });

    // Show a Success Message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.greenAccent),
            SizedBox(width: 10),
            Text("Issue Reported Successfully! (+50 XP)"),
          ],
        ),
        backgroundColor: const Color(0xFF1E212B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Static helper so we can use it inside the list
  static Widget _buildPinStatic(Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.lens_fix',
              ),
              MarkerLayer(markers: _markers), // <--- Use our dynamic list
            ],
          ),

          // LAYER 2: PROFILE ICON
          Positioned(
            top: 50, right: 20,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00F0FF), width: 2),
                color: Colors.black54,
              ),
              child: IconButton(
                icon: const Icon(Icons.person, color: Colors.white),
                onPressed: () {},
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
                color: const Color(0xFF1E212B).withOpacity(0.95),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.history, color: Colors.white70, size: 28), onPressed: () {}),
                  
                  // CAMERA BUTTON
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      height: 70, width: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F0FF).withOpacity(0.4),
                            blurRadius: 20, spreadRadius: 2,
                          )
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.black, size: 32),
                        onPressed: _openCamera, // <--- Calls our new function
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