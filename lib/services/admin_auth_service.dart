import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_user.dart';

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<AdminUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw 'Authentication failed';
      }

      // Check if user is admin
      final adminUser = await getAdminProfile(credential.user!.uid);
      if (adminUser == null || adminUser.role != 'admin') {
        await _auth.signOut();
        throw 'Access denied. Admin privileges required.';
      }

      return adminUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // Get admin profile from Firestore
  Future<AdminUser?> getAdminProfile(String uid) async {
    try {
      final doc = await _firestore.collection('admins').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AdminUser.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      throw 'Failed to fetch admin profile: ${e.toString()}';
    }
  }

  // Create admin profile (for initial setup)
  Future<AdminUser> createAdminProfile({
    required String uid,
    required String email,
    String? name,
    String? photoUrl,
  }) async {
    try {
      final adminUser = AdminUser(
        uid: uid,
        email: email,
        role: 'admin',
        createdAt: DateTime.now(),
        name: name,
        photoUrl: photoUrl,
      );

      await _firestore
          .collection('admins')
          .doc(uid)
          .set(adminUser.toFirestore());

      return adminUser;
    } catch (e) {
      throw 'Failed to create admin profile: ${e.toString()}';
    }
  }

  // Update admin profile
  Future<void> updateAdminProfile({
    required String uid,
    String? name,
    String? photoUrl,
    bool? isActive,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (name != null) updates['name'] = name;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (isActive != null) updates['isActive'] = isActive;

      await _firestore.collection('admins').doc(uid).update(updates);
    } catch (e) {
      throw 'Failed to update admin profile: ${e.toString()}';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Failed to sign out: ${e.toString()}';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send password reset email: ${e.toString()}';
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No admin account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This admin account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  // Check if user has admin privileges
  Future<bool> hasAdminPrivileges(String uid) async {
    try {
      final adminUser = await getAdminProfile(uid);
      return adminUser != null && adminUser.role == 'admin' && adminUser.isActive;
    } catch (e) {
      return false;
    }
  }

  // Get admin profile stream for real-time updates
  Stream<AdminUser?> getAdminProfileStream(String uid) {
    return _firestore
        .collection('admins')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return AdminUser.fromFirestore(doc.data()!);
      }
      return null;
    });
  }
}


