import 'package:flutter/material.dart';

class CloudSyncProvider extends ChangeNotifier {
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  String _userName = "";
  String get userName => _userName;

  Future<void> syncToCloud() async {
    if (!_isLoggedIn) return;
    _isSyncing = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    _lastSyncTime = DateTime.now();
    _isSyncing = false;
    notifyListeners();
  }

  void mockLogin(String name) {
    _isLoggedIn = true;
    _userName = name;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _userName = "";
    notifyListeners();
  }
}
