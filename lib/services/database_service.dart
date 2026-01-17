import 'dart:convert'; 
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- ADMIN & SYSTEM HELPERS ---

  // 1. Get Live Stream of All Issues (For Admin Dashboard)
  Stream<QuerySnapshot> getIssuesStream() {
    return _db.collection('issues').orderBy('timestamp', descending: true).snapshots();
  }

  // 2. Delete an Issue (Admin Power)
  Future<void> deleteIssue(String docId) async {
    await _db.collection('issues').doc(docId).delete();
  }

  // --- HELPER ACTIONS ---

  // 3. Resolve Issue (For Helpers)
  Future<void> resolveIssue(String docId) async {
    String userId = _auth.currentUser!.uid;
    
    // Mark Issue as Resolved
    await _db.collection('issues').doc(docId).update({
      'status': 'Resolved',
      'resolvedBy': userId,
      'resolvedAt': FieldValue.serverTimestamp(),
    });

    // Reward Helper (+100 XP for fixing stuff!)
    await _db.collection('users').doc(userId).update({
      'xp': FieldValue.increment(100),
      'reports': FieldValue.increment(1), 
    });
  }

  // --- UTILITIES ---

  Future<String> convertImageToBase64(File imageFile) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      return base64Encode(imageBytes);
    } catch (e) {
      throw Exception("Image Conversion Failed: $e");
    }
  }

  // --- USER MANAGEMENT ---

  Future<void> ensureUserExists(String role) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    DocumentReference userDoc = _db.collection('users').doc(user.uid);
    DocumentSnapshot snapshot = await userDoc.get();

    if (!snapshot.exists) {
      // NEW USER
      await userDoc.set({
        'email': user.email,
        'role': role.toLowerCase(), 
        'displayName': user.email!.split('@')[0], 
        'xp': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });
    } else {
      // EXISTING USER
      await userDoc.update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> updateUserProfile({String? name, String? imageBase64}) async {
    String userId = _auth.currentUser!.uid;
    Map<String, dynamic> data = {};
    if (name != null) data['displayName'] = name;
    if (imageBase64 != null) data['profileImageBase64'] = imageBase64;
    await _db.collection('users').doc(userId).set(data, SetOptions(merge: true));
  }

  // --- REPORTING LOGIC ---

  Future<void> reportIssue({
    required Map<String, dynamic> aiData, 
    required String imageBase64, 
    required Position position,
    bool isEscalation = false, // ACCEPT FLAG
  }) async {
    try {
      String userId = _auth.currentUser!.uid;
      String userEmail = _auth.currentUser!.email ?? "Unknown";

      await _db.collection('issues').add({
        'title': aiData['title'] ?? 'Report',
        'description': aiData['description'] ?? 'No description',
        'severity': aiData['severity'] ?? 'Low',
        'category': aiData['category'] ?? 'Other',
        'fix': aiData['fix'] ?? 'None',
        'imageBase64': imageBase64, 
        'location': GeoPoint(position.latitude, position.longitude),
        'status': 'Pending',
        'isEscalation': isEscalation, // SAVE FLAG
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