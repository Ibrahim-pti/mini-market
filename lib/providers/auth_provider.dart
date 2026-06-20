import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String? _username;
  String? _password;
  bool _isAuthenticated = false;
  bool _isInitialized = false;

  String? get username => _username;
  String? get password => _password;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('app_username');
    _password = prefs.getString('app_password');
    
    // If no credentials are set, we consider it authenticated
    if (_username == null || _username!.isEmpty || _password == null || _password!.isEmpty) {
      _isAuthenticated = true;
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setCredentials(String newUsername, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_username', newUsername);
    await prefs.setString('app_password', newPassword);
    _username = newUsername;
    _password = newPassword;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> removeCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_username');
    await prefs.remove('app_password');
    _username = null;
    _password = null;
    _isAuthenticated = true;
    notifyListeners();
  }

  bool authenticate(String user, String pass) {
    if (_username == user && _password == pass) {
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void lock() {
    if (_username != null && _username!.isNotEmpty && _password != null && _password!.isNotEmpty) {
      _isAuthenticated = false;
      notifyListeners();
    }
  }
}
