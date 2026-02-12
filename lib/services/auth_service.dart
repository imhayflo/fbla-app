import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String school,
    required String chapter,
    required String state,
    required String section,
    String? phone,
    String? chapterInstagramHandle,
  }) async {
    try {
      // Create user account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      if (credential.user != null) {
        await _db.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'email': email,
          'name': name,
          'school': school,
          'chapter': chapter,
          'state': state,
          'section': section,
          'phone': phone ?? '',
          'chapterInstagramHandle': chapterInstagramHandle ?? '',
          'points': 0,
          'rank': 0,
          'eventsAttended': 0,
          'memberSince': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Delete the current user account. Requires [password] for re-authentication.
  /// Deletes Firestore user document and subcollections, then Firebase Auth user.
  Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');
    if (user.email == null || user.email!.isEmpty) throw Exception('No email');
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
    final uid = user.uid;
    await _deleteUserFirestoreData(uid);
    await user.delete();
  }

  Future<void> _deleteUserFirestoreData(String uid) async {
    final userRef = _db.collection('users').doc(uid);
    final batch = _db.batch();
    batch.delete(userRef);
    final registeredEvents = await userRef.collection('registeredEvents').get();
    for (final doc in registeredEvents.docs) batch.delete(doc.reference);
    final registeredCompetitions = await userRef.collection('registeredCompetitions').get();
    for (final doc in registeredCompetitions.docs) batch.delete(doc.reference);
    await batch.commit();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}
