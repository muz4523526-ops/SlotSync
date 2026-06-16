import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email/password
  Future<String?> register({
    required String email,
    required String password,
    required String role,
    required String username,
  }) async {
    try {
      _logger.i('Attempting registration for: $email');
      _logger.i('Role: $role, Username: $username');

      // Create user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      _logger.d('Firebase Auth user created: ${userCredential.user!.uid}');

      // Save user data to Firestore
      _logger.i('Saving user data to Firestore...');
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'username': username,
        'email': email,
        'role': role, // 'patient' or 'hospital'
        'createdAt': FieldValue.serverTimestamp(),
      });

      _logger.d('User data saved to Firestore successfully');
      return null; // Success
    } on FirebaseAuthException catch (e) {
      _logger.e('FirebaseAuthException: ${e.code} - ${e.message}');
      // Return user-friendly error messages
      switch (e.code) {
        case 'weak-password':
          return 'Password should be at least 6 characters';
        case 'email-already-in-use':
          return 'An account already exists with this email';
        case 'invalid-email':
          return 'Invalid email address';
        case 'operation-not-allowed':
          return 'Email/password accounts are not enabled. Please enable Email/Password authentication in Firebase Console.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return 'Registration failed: ${e.message}';
      }
    } catch (e, stackTrace) {
      _logger.e('Unexpected error: $e', error: e, stackTrace: stackTrace);
      return 'An error occurred during registration: ${e.toString()}';
    }
  }

  // Login with email/password
  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user role from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return {
          'uid': userCredential.user!.uid,
          'email': email,
          'role': userData['role'],
          'username': userData['username'],
        };
      }

      return null;
    } on FirebaseAuthException catch (e) {
      // Return user-friendly error messages
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email');
        case 'wrong-password':
          throw Exception('Incorrect password');
        case 'invalid-email':
          throw Exception('Invalid email address');
        case 'user-disabled':
          throw Exception('This account has been disabled');
        default:
          throw Exception(e.message ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('An error occurred during login: ${e.toString()}');
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get user role
  Future<String?> getUserRole(String uid) async {
    DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(uid)
        .get();
    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      return data['role'];
    }
    return null;
  }
}
