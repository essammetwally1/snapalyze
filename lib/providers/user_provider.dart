import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapalyze/models/user_model.dart';
import 'package:snapalyze/shared/consts.dart'; // contains rememberMeKey & rememberUser (if you have it)

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _rememberMe = false;

  UserModel? get currentUser => _currentUser;
  bool get rememberMe => _rememberMe;
  bool get isLoggedIn => _currentUser != null;

  /// Call this ONCE at app start to restore remembered session (if any).
  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool(Consts.rememberMeKey) ?? false;

    if (_rememberMe) {
      final jsonStr = prefs.getString(Consts.rememberUser);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        try {
          final Map<String, dynamic> json = jsonDecode(jsonStr);
          _currentUser = UserModel.fromJson(json);
        } catch (_) {
          // If decode fails, clear the bad data
          await _clearPrefs(prefs);
          _currentUser = null;
          _rememberMe = false;
        }
      } else {
        _currentUser = null;
        _rememberMe = false;
      }
    } else {
      _currentUser = null;
    }

    notifyListeners();
  }

  /// Set current user, optionally remember on next launch.
  Future<void> setUser(UserModel user, {bool remember = false}) async {
    _currentUser = user;
    _rememberMe = remember;

    final prefs = await SharedPreferences.getInstance();
    if (remember) {
      await prefs.setBool(Consts.rememberMeKey, true);
      await prefs.setString(Consts.rememberUser, jsonEncode(user.toJson()));
    } else {
      // Don’t remember across launches
      await _clearPrefs(prefs);
    }

    notifyListeners();
  }

  /// Toggle remember-me without changing the user.
  Future<void> setRememberMe(bool remember) async {
    _rememberMe = remember;
    final prefs = await SharedPreferences.getInstance();
    if (!remember) {
      // If turning it off, drop stored user
      await _clearPrefs(prefs);
    } else if (_currentUser != null) {
      // If turning it on and a user exists, store it
      await prefs.setBool(Consts.rememberMeKey, true);
      await prefs.setString(
        Consts.rememberUser,
        jsonEncode(_currentUser!.toJson()),
      );
    }
    notifyListeners();
  }

  /// Logout: clear memory + disk.
  Future<void> signOut() async {
    _currentUser = null;
    _rememberMe = false;
    final prefs = await SharedPreferences.getInstance();
    await _clearPrefs(prefs);
    notifyListeners();
  }

  // -------- Helpers --------
  Future<void> _clearPrefs(SharedPreferences prefs) async {
    await prefs.remove(Consts.rememberMeKey);
    await prefs.remove(Consts.rememberUser);
  }
}
