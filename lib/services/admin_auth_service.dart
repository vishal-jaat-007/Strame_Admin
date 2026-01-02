import 'dart:core';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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
      print('🔑 [AdminAuthService] Attempting Firebase sign in for: $email');
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print('✅ [AdminAuthService] Firebase auth successful');
      if (credential.user == null) {
        print('❌ [AdminAuthService] Credential user is null!');
        throw 'Authentication failed';
      }

      print('👤 [AdminAuthService] User UID: ${credential.user!.uid}');
      print('📧 [AdminAuthService] User Email: ${credential.user!.email}');

      // Check if user is admin
      print('🔍 [AdminAuthService] Fetching admin profile from Firestore...');
      final adminUser = await getAdminProfile(credential.user!.uid);

      if (adminUser == null) {
        print('❌ [AdminAuthService] Admin profile NOT FOUND in Firestore!');
        print(
          '🔍 [AdminAuthService] Searched in collection: admins, doc: ${credential.user!.uid}',
        );
        await _auth.signOut();
        throw 'Access denied. Admin profile not found in database.';
      }

      print('✅ [AdminAuthService] Admin profile found: ${adminUser.email}');
      print(
        '📋 [AdminAuthService] Role: ${adminUser.role}, Active: ${adminUser.isActive}',
      );

      if (adminUser.role != 'admin') {
        print(
          '❌ [AdminAuthService] User role is "${adminUser.role}", not "admin"',
        );
        await _auth.signOut();
        throw 'Access denied. Admin privileges required.';
      }

      print('✅ [AdminAuthService] Sign in successful! Returning admin user.');
      return adminUser;
    } on FirebaseAuthException catch (e) {
      print(
        '❌ [AdminAuthService] FirebaseAuthException: ${e.code} - ${e.message}',
      );
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ [AdminAuthService] General error: $e');
      throw e.toString();
    }
  }

  // Get admin profile from Firestore
  Future<AdminUser?> getAdminProfile(String uid) async {
    try {
      print('📥 [AdminAuthService] Fetching admin profile for UID: $uid');
      print('🔍 [AdminAuthService] Collection: admins, Document: $uid');

      final doc = await _firestore.collection('admins').doc(uid).get();

      print('📄 [AdminAuthService] Document exists: ${doc.exists}');
      print('📄 [AdminAuthService] Document has data: ${doc.data() != null}');

      if (doc.exists && doc.data() != null) {
        print('✅ [AdminAuthService] Admin document found, parsing data...');
        print('📋 [AdminAuthService] Document data: ${doc.data()}');
        final adminUser = AdminUser.fromFirestore(doc.data()!);
        print('✅ [AdminAuthService] AdminUser parsed successfully');
        return adminUser;
      }

      print('⚠️ [AdminAuthService] Admin profile does not exist in Firestore!');
      return null;
    } catch (e) {
      print('❌ [AdminAuthService] Error fetching admin profile: $e');
      throw 'Failed to fetch admin profile: ${e.toString()}';
    }
  }

  // Create admin profile (for initial setup)
  Future<AdminUser> createAdminProfile({
    required String uid,
    required String email,
    String? name,
    String? photoUrl,
    String role = 'admin',
  }) async {
    try {
      final adminUser = AdminUser(
        uid: uid,
        email: email,
        role: role,
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
      print('🔐 [AdminAuthService] Checking admin privileges for UID: $uid');
      final adminUser = await getAdminProfile(uid);

      if (adminUser == null) {
        print('❌ [AdminAuthService] Admin user is null - NO PRIVILEGES');
        return false;
      }

      final hasPrivileges = adminUser.role == 'admin' && adminUser.isActive;
      print(
        '📋 [AdminAuthService] Role: ${adminUser.role}, Active: ${adminUser.isActive}',
      );
      print('✅ [AdminAuthService] Has privileges: $hasPrivileges');

      return hasPrivileges;
    } catch (e) {
      print('❌ [AdminAuthService] Error checking privileges: $e');
      return false;
    }
  }

  // Get admin profile stream for real-time updates
  Stream<AdminUser?> getAdminProfileStream(String uid) {
    return _firestore.collection('admins').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return AdminUser.fromFirestore(doc.data()!);
      }
      return null;
    });
  }

  // Create a new admin account
  Future<void> createAdmin({
    required String email,
    required String password,
    required String name,
    String role = 'admin',
  }) async {
    FirebaseApp? secondaryApp;
    try {
      print('🚀 [AdminAuthService] Creating new admin: $email');

      // Initialize a secondary app to create user without signing out current user
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // Create user in Firebase Auth
      print('🔐 [AdminAuthService] Creating user in Firebase Auth...');
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      print('✅ [AdminAuthService] User created with UID: $uid');

      // Create admin profile in Firestore
      print('📝 [AdminAuthService] Creating admin profile in Firestore...');
      await createAdminProfile(uid: uid, email: email, name: name, role: role);

      print('✅ [AdminAuthService] Admin profile created successfully');

      await secondaryApp.delete();
    } catch (e) {
      print('❌ [AdminAuthService] Error creating admin: $e');
      await secondaryApp?.delete();
      throw e.toString();
    }
  }

  // Get all admins stream
  Stream<List<AdminUser>> getAdminsStream() {
    return _firestore
        .collection('admins')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => AdminUser.fromFirestore(doc.data()))
                  .toList(),
        );
  }

  // Delete an admin
  Future<void> deleteAdmin(String uid) async {
    try {
      await _firestore.collection('admins').doc(uid).delete();
    } catch (e) {
      throw 'Failed to delete admin: ${e.toString()}';
    }
  }
}
