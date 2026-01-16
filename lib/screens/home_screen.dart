import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // The Map
import 'package:latlong2/latlong.dart';      // Coordinates
import 'package:lens_fix/screens/camera_screen.dart'; // We will create this next
// import 'package:lens_fix/screens/profile_screen.dart'; 
// import 'package:lens_fix/screens/leaderboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Allow map to go behind the status bar
      extendBodyBehindAppBar: true,
      
      body: Stack(
        children: [
          // -------------------------------------------
          // LAYER 1: THE LIVING MAP
          // -------------------------------------------
          FlutterMap(
            options: MapOptions(
              // Centered on IIIT Sri City
              initialCenter: const LatLng(13.5560, 80.0260), 
              initialZoom: 16.5,
              // Setup interaction flags (pinch, zoom, etc.)
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                // We use standard OSM tiles. 
                // Hack: You can use 'CartoDB Dark Matter' for a dark theme map, 
                // but let's stick to standard for reliability first.
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.lens_fix',
              ),
              
              // THE PINS (Data Layer)
              MarkerLayer(
                markers: [
                  // 🔴 Example: Unresolved Issue (Broken Light)
                  Marker(
                    point: const LatLng(13.5562, 80.0265),
                    width: 50,
                    height: 50,
                    child: _buildPin(Colors.redAccent, Icons.electrical_services),
                  ),
                  // 🟢 Example: Resolved Issue (Pothole Fixed)
                  Marker(
                    point: const LatLng(13.5555, 80.0255),
                    width: 40,
                    height: 40,
                    child: _buildPin(Colors.greenAccent, Icons.check),
                  ),
                ],
              ),
            ],
          ),

          // -------------------------------------------
          // LAYER 2: TOP RIGHT IDENTITY (Profile)
          // -------------------------------------------
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00F0FF), width: 2), // Neon Cyan Border
                color: Colors.black54,
              ),
              child: IconButton(
                icon: const Icon(Icons.person, color: Colors.white),
                onPressed: () {
                  // Navigate to Profile (We will build this later)
                },
              ),
            ),
          ),

          // -------------------------------------------
          // LAYER 3: THE FLOATING COMMAND DOCK
          // -------------------------------------------
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E212B).withOpacity(0.95), // Dark Slate
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
                  // 1. History Button
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.white70, size: 28),
                    onPressed: () {},
                  ),

                  // 2. THE HERO CAMERA BUTTON (Center)
                  Transform.translate(
                    offset: const Offset(0, -20), // Move it UP slightly
                    child: Container(
                      height: 70, 
                      width: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F0FF), // Neon Cyan
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F0FF).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.black, size: 32),
                        onPressed: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (_) => const CameraScreen())
                          );
                        },
                      ),
                    ),
                  ),

                  // 3. Leaderboard Button
                  IconButton(
                    icon: const Icon(Icons.emoji_events_outlined, color: Colors.white70, size: 28),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget for Map Pins
  Widget _buildPin(Color color, IconData icon) {
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
}