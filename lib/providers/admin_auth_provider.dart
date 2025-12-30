import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/admin_auth_service.dart';
import '../models/admin_user.dart';

class AdminAuthProvider extends ChangeNotifier {
  final AdminAuthService _authService = AdminAuthService();
  AdminUser? _currentAdmin;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;
  StreamSubscription<AdminUser?>? _adminSubscription;

  // Getters
  AdminUser? get currentAdmin => _currentAdmin;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentAdmin != null;
  String get adminName =>
      _currentAdmin?.name ?? _currentAdmin?.email ?? 'Admin';

  // Initialize auth state listener
  void initialize() {
    if (_isInitialized) {
      print('🔄 [AdminAuthProvider] Already initialized, skipping...');
      return;
    }

    print('🚀 [AdminAuthProvider] Initializing auth state listener...');
    _isInitialized = true;

    _authService.authStateChanges.listen((User? user) async {
      print(
        '📡 [AdminAuthProvider] Auth state changed: ${user != null ? "User logged in (${user.uid})" : "No user logged in"}',
      );

      if (user != null) {
        print('👤 [AdminAuthProvider] User found: ${user.email}');

        // Cancel previous subscription
        await _adminSubscription?.cancel();
        print('🔄 [AdminAuthProvider] Previous subscription cancelled');

        // Check if user has admin privileges
        print(
          '🔍 [AdminAuthProvider] Checking admin privileges for UID: ${user.uid}',
        );
        final hasPrivileges = await _authService.hasAdminPrivileges(user.uid);
        print('✅ [AdminAuthProvider] Has admin privileges: $hasPrivileges');

        if (!hasPrivileges) {
          print(
            '❌ [AdminAuthProvider] Access denied! User does not have admin privileges',
          );
          print('🔐 [AdminAuthProvider] Signing out user...');
          await _authService.signOut();
          _currentAdmin = null;
          _errorMessage = 'Access denied. Admin privileges required.';
          print(
            '❌ [AdminAuthProvider] User signed out due to insufficient privileges',
          );
          notifyListeners();
          return;
        }

        print(
          '📺 [AdminAuthProvider] Subscribing to admin profile stream for UID: ${user.uid}',
        );
        // Subscribe to real-time admin profile updates
        _adminSubscription = _authService
            .getAdminProfileStream(user.uid)
            .listen(
              (adminUser) {
                print(
                  '📥 [AdminAuthProvider] Admin profile received from stream',
                );
                if (adminUser != null) {
                  print(
                    '✅ [AdminAuthProvider] Admin User: ${adminUser.email}, Role: ${adminUser.role}, Active: ${adminUser.isActive}',
                  );
                } else {
                  print('⚠️ [AdminAuthProvider] Admin user is NULL!');
                }

                _currentAdmin = adminUser;
                if (adminUser == null || !adminUser.isActive) {
                  _errorMessage = 'Admin account is inactive.';
                  print(
                    '❌ [AdminAuthProvider] Admin account is inactive or null',
                  );
                } else {
                  _errorMessage = null;
                  print(
                    '✅ [AdminAuthProvider] Admin account is active and ready',
                  );
                }
                print('🔔 [AdminAuthProvider] Notifying listeners...');
                notifyListeners();
              },
              onError: (error) {
                print(
                  '❌ [AdminAuthProvider] Error in admin profile stream: $error',
                );
                _errorMessage = error.toString();
                notifyListeners();
              },
            );
      } else {
        print('👋 [AdminAuthProvider] User logged out');
        await _adminSubscription?.cancel();
        _currentAdmin = null;
        print('🔔 [AdminAuthProvider] Notifying listeners (logged out)...');
        notifyListeners();
      }
    });
  }

  // Sign in
  Future<bool> signIn({required String email, required String password}) async {
    try {
      print('🔐 [AdminAuthProvider] Starting sign in process for: $email');
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      print(
        '📞 [AdminAuthProvider] Calling auth service signInWithEmailAndPassword...',
      );
      _currentAdmin = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print(
        '✅ [AdminAuthProvider] Sign in completed. Admin: ${_currentAdmin?.email ?? "null"}',
      );
      _isLoading = false;
      notifyListeners();

      final success = _currentAdmin != null;
      print('📊 [AdminAuthProvider] Sign in success: $success');
      return success;
    } catch (e) {
      print('❌ [AdminAuthProvider] Sign in error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();
      _currentAdmin = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.resetPassword(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update admin profile
  Future<bool> updateProfile({String? name, String? photoUrl}) async {
    if (_currentAdmin == null) return false;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.updateAdminProfile(
        uid: _currentAdmin!.uid,
        name: name,
        photoUrl: photoUrl,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Load admin profile (one-time fetch)
  Future<void> loadAdminProfile(String uid) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentAdmin = await _authService.getAdminProfile(uid);

      if (_currentAdmin == null || !_currentAdmin!.isActive) {
        _errorMessage = 'Admin account not found or inactive.';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _adminSubscription?.cancel();
    super.dispose();
  }
}

// Global instance
final adminAuthProvider = AdminAuthProvider();

