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
  String get adminName => _currentAdmin?.name ?? _currentAdmin?.email ?? 'Admin';

  // Initialize auth state listener
  void initialize() {
    if (_isInitialized) return;
    
    _isInitialized = true;
    
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        // Cancel previous subscription
        await _adminSubscription?.cancel();
        
        // Check if user has admin privileges
        final hasPrivileges = await _authService.hasAdminPrivileges(user.uid);
        if (!hasPrivileges) {
          await _authService.signOut();
          _currentAdmin = null;
          _errorMessage = 'Access denied. Admin privileges required.';
          notifyListeners();
          return;
        }
        
        // Subscribe to real-time admin profile updates
        _adminSubscription = _authService.getAdminProfileStream(user.uid).listen(
          (adminUser) {
            _currentAdmin = adminUser;
            if (adminUser == null || !adminUser.isActive) {
              _errorMessage = 'Admin account is inactive.';
            } else {
              _errorMessage = null;
            }
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            notifyListeners();
          },
        );
      } else {
        await _adminSubscription?.cancel();
        _currentAdmin = null;
        notifyListeners();
      }
    });
  }

  // Sign in
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentAdmin = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return _currentAdmin != null;
    } catch (e) {
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
  Future<bool> updateProfile({
    String? name,
    String? photoUrl,
  }) async {
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



