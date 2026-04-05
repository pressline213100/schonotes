import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class CloudSyncProvider extends ChangeNotifier {
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  String _userName = "";
  String get userName => _userName;
  
  bool _autoSync = true;
  bool get autoSync => _autoSync;
  
  CloudSyncProvider() {
    _loadState();
    _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    await GoogleSignIn.instance.initialize(
      clientId: '1051959355302-mjh8pqn2g9at44nq585pva8e4eilftiu.apps.googleusercontent.com',
    );
    
    // Listen to Google Sign-In state changes
    GoogleSignIn.instance.authenticationEvents.listen((GoogleSignInAuthenticationEvent event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
         _isLoggedIn = true;
         _userName = event.user.displayName ?? event.user.email;
         _saveState();
         notifyListeners();
         if (_autoSync) syncToCloud();
      } else if (event is GoogleSignInAuthenticationEventSignOut) {
         _isLoggedIn = false;
         _userName = "";
         _saveState();
         notifyListeners();
      }
    });
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _userName = prefs.getString('userName') ?? "";
    _autoSync = prefs.getBool('autoSync') ?? true;
    final lastSyncStr = prefs.getString('lastSyncTime');
    if (lastSyncStr != null) {
      _lastSyncTime = DateTime.tryParse(lastSyncStr);
    }
    notifyListeners();
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', _isLoggedIn);
    await prefs.setString('userName', _userName);
    await prefs.setBool('autoSync', _autoSync);
    if (_lastSyncTime != null) {
      await prefs.setString('lastSyncTime', _lastSyncTime!.toIso8601String());
    }
  }

  void toggleAutoSync(bool value) {
    _autoSync = value;
    _saveState();
    notifyListeners();
  }

  Future<void> syncToCloud() async {
    if (!_isLoggedIn) return;
    _isSyncing = true;
    notifyListeners();
    // Simulate network delay for upload/download
    await Future.delayed(const Duration(seconds: 3));
    _lastSyncTime = DateTime.now();
    _isSyncing = false;
    _saveState();
    notifyListeners();
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      await GoogleSignIn.instance.authenticate();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Login Failed: $error'))
      );
    }
  }

  void mockLogin(String name) {
    // Kept for fallback, but deprecated in UI logic
  }

  Future<void> logout() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    
    _isLoggedIn = false;
    _userName = "";
    _lastSyncTime = null;
    _saveState();
    notifyListeners();
  }
}
