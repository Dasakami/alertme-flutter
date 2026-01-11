import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static const String _userKey = 'current_user';
  static const String _contactsKey = 'emergency_contacts';
  static const String _sosEventsKey = 'sos_events';
  static const String _safetyTimerKey = 'safety_timer';
  static const String _onboardingKey = 'onboarding_completed';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  Future<void> saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('Error saving string: $e');
    }
  }

  Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      debugPrint('Error getting string: $e');
      return null;
    }
  }

  Future<void> saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('Error saving bool: $e');
    }
  }

  Future<bool> getBool(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? false;
    } catch (e) {
      debugPrint('Error getting bool: $e');
      return false;
    }
  }

  Future<void> saveJson(String key, Map<String, dynamic> json) async {
    try {
      await saveString(key, jsonEncode(json));
    } catch (e) {
      debugPrint('Error saving JSON: $e');
    }
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    try {
      final str = await getString(key);
      if (str == null) return null;
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting JSON: $e');
      return null;
    }
  }

  Future<void> saveJsonList(String key, List<Map<String, dynamic>> list) async {
    try {
      await saveString(key, jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving JSON list: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getJsonList(String key) async {
    try {
      final str = await getString(key);
      if (str == null) return [];
      final decoded = jsonDecode(str);
      return (decoded as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting JSON list: $e');
      return [];
    }
  }

  Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      debugPrint('Error removing key: $e');
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('Error clearing storage: $e');
    }
  }

  String get userKey => _userKey;
  String get contactsKey => _contactsKey;
  String get sosEventsKey => _sosEventsKey;
  String get safetyTimerKey => _safetyTimerKey;
  String get onboardingKey => _onboardingKey;

  Future<void> saveTokens(String access, String refresh) async {
    await saveString(_accessTokenKey, access);
    await saveString(_refreshTokenKey, refresh);
  }

  Future<void> saveAccessToken(String access) async {
    await saveString(_accessTokenKey, access);
  }

  Future<String?> getAccessToken() => getString(_accessTokenKey);
  Future<String?> getRefreshToken() => getString(_refreshTokenKey);

  Future<void> clearTokens() async {
    await remove(_accessTokenKey);
    await remove(_refreshTokenKey);
  }
}