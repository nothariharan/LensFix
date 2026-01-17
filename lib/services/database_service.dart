import 'dart:convert'; 
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- ADMIN ACTIONS ---
  
  Future<void> toggleUrgentStatus(String docId, bool currentStatus) async {
    await _db.collection('issues').doc(docId).update({
      'isUrgent': !currentStatus,
    });
  }

  Stream<QuerySnapshot> getIssuesStream() {
    return _db.collection('issues').orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> deleteIssue(String docId) async {
    await _db.collection('issues').doc(docId).delete();
  }

  // --- HELPER ACTIONS ---

  Future<void> resolveIssue(String docId) async {
    String userId = _auth.currentUser!.uid;
    
    // 1. Update the issue status
    await _db.collection('issues').doc(docId).update({
      'status': 'Resolved',
      'resolvedBy': userId,
      'resolvedAt': FieldValue.serverTimestamp(),
    });

    // 2. Update the Helper's persistent stats
    await _db.collection('users').doc(userId).update({
      'xp': FieldValue.increment(100),
      'reports': FieldValue.increment(1), 
      'fixedCount': FieldValue.increment(1), // NEW: Persistent counter
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

  // --- USER SYNC & MIGRATION ---

  Future<void> ensureUserExists(String role) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    DocumentReference userDoc = _db.collection('users').doc(user.uid);
    DocumentSnapshot snapshot = await userDoc.get();

    if (!snapshot.exists) {
      final query = await _db.collection('users').where('email', isEqualTo: user.email).get();

      if (query.docs.isNotEmpty) {
        var preAuthDoc = query.docs.first;
        var data = preAuthDoc.data() as Map<String, dynamic>;

        await userDoc.set({
          ...data,
          'lastActive': FieldValue.serverTimestamp(),
        });

        if (preAuthDoc.id != user.uid) {
          await _db.collection('users').doc(preAuthDoc.id).delete();
        }
      } else {
        await userDoc.set({
          'email': user.email,
          'role': role.toLowerCase(),
          'displayName': user.email!.split('@')[0],
          'xp': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
    } else {
      await userDoc.update({'lastActive': FieldValue.serverTimestamp()});
    }
  }

  Future<void> updateUserProfile({String? name, String? imageBase64}) async {
    String userId = _auth.currentUser!.uid;
    Map<String, dynamic> data = {};
    if (name != null) data['displayName'] = name;
    if (imageBase64 != null) data['profileImageBase64'] = imageBase64;
    await _db.collection('users').doc(userId).set(data, SetOptions(merge: true));
  }

  // --- REPORTING ---

  // --- UPDATED REPORTING WITH BUILDING & FLOOR ---

  // --- DATABASE SERVICE UPDATE ---
  Future<void> reportIssue({
    required Map<String, dynamic> aiData, 
    required String imageBase64, 
    required Position position,
    required String building, 
    required String floor,    
    bool isEscalation = false, 
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
        'building': building, 
        'floor': floor,       
        'status': 'Pending',
        'isEscalation': isEscalation,
        'isUrgent': false, 
        'reportedBy': userId,
        'reporterEmail': userEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'upvotes': 0,
        'upvotedBy': [],
      });

      // --- FIXED LOGIC: Increments 'reports' for students ---
      await _db.collection('users').doc(userId).set({
        'email': userEmail,
        'xp': FieldValue.increment(50),      
        'reports': FieldValue.increment(1), // <--- ADD THIS LINE
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

    } catch (e) {
      throw Exception("Database Save Failed: $e");
    }
  }

  // --- NEW: UPVOTE & DYNAMIC ESCALATION ---

  Future<void> upvoteIssue(String docId, Position userPos) async {
    String userId = _auth.currentUser!.uid;
    DocumentReference issueRef = _db.collection('issues').doc(docId);
    DocumentSnapshot doc = await issueRef.get();
    
    if (!doc.exists) return;
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    GeoPoint issueGeo = data['location'];

    // Proximity Check (20 meters)
    double distance = Geolocator.distanceBetween(
      userPos.latitude, userPos.longitude, 
      issueGeo.latitude, issueGeo.longitude
    );

    if (distance > 20) throw Exception("Too far away to verify. Move closer.");

    List<dynamic> upvotedBy = data['upvotedBy'] ?? [];
    if (upvotedBy.contains(userId)) throw Exception("Already verified.");

    int newUpvotes = (data['upvotes'] ?? 0) + 1;
    String newSeverity = data['severity'];
    bool newIsUrgent = data['isUrgent'] ?? false;

    // Escalation Logic
    if (newUpvotes >= 20) {
      newSeverity = "High";
      newIsUrgent = true;
    } else if (newUpvotes >= 10) {
      newSeverity = "High";
    } else if (newUpvotes >= 5) {
      newSeverity = "Medium";
    }

    await issueRef.update({
      'upvotes': newUpvotes,
      'upvotedBy': FieldValue.arrayUnion([userId]),
      'severity': newSeverity,
      'isUrgent': newIsUrgent,
    });
  }
}