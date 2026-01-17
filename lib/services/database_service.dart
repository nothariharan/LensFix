import 'dart:convert'; // Import this for Base64
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. CONVERT IMAGE TO STRING (No Storage Bucket needed)
  Future<String> convertImageToBase64(File imageFile) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      return base64Image;
    } catch (e) {
      throw Exception("Image Conversion Failed: $e");
    }
  }

  // 2. SAVE ISSUE (Stores the image string directly in the DB)
  Future<void> reportIssue({
    required Map<String, dynamic> aiData, 
    required String imageBase64, // Changed from imageUrl to imageBase64
    required Position position,
  }) async {
    try {
      String userId = _auth.currentUser!.uid;
      String userEmail = _auth.currentUser!.email ?? "Unknown";

      await _db.collection('issues').add({
        'title': aiData['title'] ?? 'Report',
        'description': aiData['description'] ?? 'No description',
        'severity': aiData['severity'] ?? 'Low',
        'fix': aiData['fix'] ?? 'None',
        'imageBase64': imageBase64, // Saving the actual image data here
        'location': GeoPoint(position.latitude, position.longitude),
        'status': 'Pending',
        'reportedBy': userId,
        'reporterEmail': userEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'upvotes': 0,
      });
    } catch (e) {
      throw Exception("Database Save Failed: $e");
    }
  }
}