import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void mockLogin(String name) {
    _isLoggedIn = true;
    _userName = name;
    _saveState();
    notifyListeners();
    
    // Auto sync on login
    if (_autoSync) syncToCloud();
  }

  void logout() {
    _isLoggedIn = false;
    _userName = "";
    _lastSyncTime = null;
    _saveState();
    notifyListeners();
  }
}
