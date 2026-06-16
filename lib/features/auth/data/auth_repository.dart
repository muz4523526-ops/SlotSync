import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/models/user_model.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  static bool get isGoogleSignInSupportedOnCurrentPlatform =>
      isGoogleSignInSupported(isWeb: kIsWeb, platform: defaultTargetPlatform);

  static String get googleSignInUnavailableMessage =>
      unsupportedGoogleSignInMessage(
        isWeb: kIsWeb,
        platform: defaultTargetPlatform,
      );

  static bool isGoogleSignInSupported({
    required bool isWeb,
    required TargetPlatform platform,
  }) {
    if (isWeb) return true;

    switch (platform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  static String unsupportedGoogleSignInMessage({
    required bool isWeb,
    required TargetPlatform platform,
  }) {
    if (isWeb || isGoogleSignInSupported(isWeb: isWeb, platform: platform)) {
      return '';
    }

    switch (platform) {
      case TargetPlatform.windows:
        return 'Google sign-in is not available on Windows builds yet. '
            'Use email/password here, or run the app on Android or the web.';
      case TargetPlatform.linux:
        return 'Google sign-in is not available on Linux builds yet. '
            'Use email/password here, or run the app on Android or the web.';
      case TargetPlatform.fuchsia:
        return 'Google sign-in is not available on this platform.';
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return '';
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<String> getUserRole(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    return doc.data()?['role'] as String? ?? AppConstants.rolePatient;
  }

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      final userModel = UserModel(
        id: uid,
        email: email.trim(),
        name: name.trim(),
        role: role,
        phone: phone,
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(userModel.toMap());
      if (role == AppConstants.roleHospital) {
        await _firestore
            .collection(AppConstants.hospitalsCollection)
            .doc(uid)
            .set({
              'name': name.trim(),
              'email': email.trim(),
              'phone': phone,
              'isVerified': false,
              'verificationStatus': 'pending',
              'createdAt': FieldValue.serverTimestamp(),
            });
      }
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Sign up failed', code: e.code);
    }
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(credential.user!.uid)
          .get();
      if (!doc.exists) throw const AuthException('User profile not found');
      return UserModel.fromFirestore(doc);
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Sign in failed', code: e.code);
    }
  }

  Future<UserModel> signInWithGoogle({required String role}) async {
    try {
      if (!isGoogleSignInSupportedOnCurrentPlatform) {
        throw AuthException(googleSignInUnavailableMessage);
      }

      GoogleSignInAccount? googleUser;

      googleUser = await _googleSignIn.signInSilently();
      googleUser ??= await _googleSignIn.signIn();

      if (googleUser == null) {
        throw const AuthException('Google sign in cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final uid = userCredential.user!.uid;

      final docRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid);
      final doc = await docRef.get();
      if (doc.exists) return UserModel.fromFirestore(doc);

      final userModel = UserModel(
        id: uid,
        email: userCredential.user!.email ?? '',
        name: userCredential.user!.displayName ?? 'User',
        role: role,
        photoUrl: userCredential.user!.photoURL,
        createdAt: DateTime.now(),
      );
      await docRef.set(userModel.toMap());
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Google sign in failed', code: e.code);
    } on PlatformException catch (e) {
      throw _mapGoogleSignInError(e);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw _mapGoogleSignInError(e);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Password reset failed', code: e.code);
    }
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @visibleForTesting
  static AuthException mapGoogleSignInErrorForTest(
    Object error, {
    bool isWeb = false,
    TargetPlatform platform = TargetPlatform.android,
  }) {
    return _mapGoogleSignInError(error, isWeb: isWeb, platform: platform);
  }

  static AuthException _mapGoogleSignInError(
    Object error, {
    bool? isWeb,
    TargetPlatform? platform,
  }) {
    final normalizedMessage = error.toString().toLowerCase();
    final currentIsWeb = isWeb ?? kIsWeb;
    final currentPlatform = platform ?? defaultTargetPlatform;

    if (normalizedMessage.contains('apiexception: 10') ||
        normalizedMessage.contains('developer_error') ||
        normalizedMessage.contains('12500')) {
      return const AuthException(
        'Google Sign-In is not configured for this Android app yet. '
        'Add the app SHA-1/SHA-256 fingerprints in Firebase, enable the Google provider, '
        'then download an updated google-services.json.',
      );
    }

    if (normalizedMessage.contains('network_error') ||
        normalizedMessage.contains('network request failed')) {
      return const AuthException(
        'Google sign in failed because the network request did not complete. '
        'Check your internet connection and try again.',
      );
    }

    if (normalizedMessage.contains('canceled') ||
        normalizedMessage.contains('cancelled')) {
      return const AuthException('Google sign in cancelled');
    }

    if (normalizedMessage.contains('unsupported')) {
      return AuthException(
        unsupportedGoogleSignInMessage(
          isWeb: currentIsWeb,
          platform: currentPlatform,
        ),
      );
    }

    if (error is PlatformException) {
      return AuthException(
        error.message ?? 'Google sign in failed',
        code: error.code,
      );
    }

    return const AuthException('Google sign in failed');
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).getCurrentUserProfile();
});
