import 'dart:convert'; 
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> convertImageToBase64(File imageFile) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      return base64Encode(imageBytes);
    } catch (e) {
      throw Exception("Image Conversion Failed: $e");
    }
  }

  Future<void> reportIssue({
    required Map<String, dynamic> aiData, 
    required String imageBase64, 
    required Position position,
  }) async {
    try {
      String userId = _auth.currentUser!.uid;
      String userEmail = _auth.currentUser!.email ?? "Unknown";

      // 1. Save the Issue
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

      // 2. Update User Stats (The Gamification Part)
      // This creates the user doc if it doesn't exist, or updates it if it does.
      await _db.collection('users').doc(userId).set({
        'email': userEmail,
        'xp': FieldValue.increment(50),      // +50 XP
        'reports': FieldValue.increment(1),  // +1 Report Count
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

    } catch (e) {
      throw Exception("Database Save Failed: $e");
    }
  }
}