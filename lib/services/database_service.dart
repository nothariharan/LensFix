import 'dart:convert'; 
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper: Convert File to Base64
  Future<String> convertImageToBase64(File imageFile) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      return base64Encode(imageBytes);
    } catch (e) {
      throw Exception("Image Conversion Failed: $e");
    }
  }

  // --- NEW: RUNS ON LOGIN TO SET UP ROLE ---
  Future<void> ensureUserExists(String role) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    DocumentReference userDoc = _db.collection('users').doc(user.uid);
    DocumentSnapshot snapshot = await userDoc.get();

    if (!snapshot.exists) {
      // NEW USER: Create with selected role and default name
      await userDoc.set({
        'email': user.email,
        'role': role.toLowerCase(), // 'student', 'helper', 'admin'
        'displayName': user.email!.split('@')[0], // Default name (allows lowercase)
        'xp': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });
    } else {
      // EXISTING USER: Just update Last Active (Don't overwrite Name/Photo/Role)
      await userDoc.update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    }
  }

  // 1. Update User Profile (Name & Photo)
  Future<void> updateUserProfile({String? name, String? imageBase64}) async {
    String userId = _auth.currentUser!.uid;
    Map<String, dynamic> data = {};
    
    if (name != null) data['displayName'] = name; // Saves exactly as typed
    if (imageBase64 != null) data['profileImageBase64'] = imageBase64;

    await _db.collection('users').doc(userId).set(data, SetOptions(merge: true));
  }

  // 2. Report Issue (With Gamification)
  Future<void> reportIssue({
    required Map<String, dynamic> aiData, 
    required String imageBase64, 
    required Position position,
  }) async {
    try {
      String userId = _auth.currentUser!.uid;
      String userEmail = _auth.currentUser!.email ?? "Unknown";

      // Save Issue
      await _db.collection('issues').add({
        'title': aiData['title'] ?? 'Report',
        'description': aiData['description'] ?? 'No description',
        'severity': aiData['severity'] ?? 'Low',
        'category': aiData['category'] ?? 'Other',
        'fix': aiData['fix'] ?? 'None',
        'imageBase64': imageBase64, 
        'location': GeoPoint(position.latitude, position.longitude),
        'status': 'Pending',
        'reportedBy': userId,
        'reporterEmail': userEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'upvotes': 0,
      });

      // Update User XP
      await _db.collection('users').doc(userId).set({
        'email': userEmail,
        'xp': FieldValue.increment(50),      
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

    } catch (e) {
      throw Exception("Database Save Failed: $e");
    }
  }
}