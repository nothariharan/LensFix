import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user (if already logged in)
  User? get currentUser => _auth.currentUser;

  // Sign Up (Register new user)
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      return result.user;
    } catch (e) {
      throw e; // Pass error to UI to handle (e.g. "Email already in use")
    }
  }

  // Sign In (Login existing user)
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return result.user;
    } catch (e) {
      throw e; // Pass error to UI (e.g. "Wrong password")
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}