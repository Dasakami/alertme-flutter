import 'package:flutter/foundation.dart';
import 'package:alertme/models/user.dart';
import 'package:alertme/services/storage_service.dart';
import 'package:alertme/services/api_client.dart';
import 'dart:convert';

class AuthService {
  final StorageService _storage = StorageService();
  final ApiClient _api = ApiClient();

  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void> init() async {
    await loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    try {
      final json = await _storage.getJson(_storage.userKey);
      if (json != null) {
        _currentUser = User.fromJson(json);
      } else {
        // If tokens exist but user not cached, we can create a minimal user from phone in token payload.
        final access = await _storage.getAccessToken();
        if (access != null && access.isNotEmpty) {
          // Attempt to decode JWT payload (not verifying) to extract username/phone
          try {
            final parts = access.split('.');
            if (parts.length == 3) {
              final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
              final username = payload['username']?.toString() ?? payload['user_id']?.toString() ?? '';
              final now = DateTime.now();
              _currentUser = User(
                id: username.isNotEmpty ? username : now.millisecondsSinceEpoch.toString(),
                phoneNumber: username,
                name: 'Пользователь',
                preferredLanguage: 'ru',
                subscriptionTier: SubscriptionTier.free,
                createdAt: now,
                updatedAt: now,
              );
              await _storage.saveJson(_storage.userKey, _currentUser!.toJson());
            }
          } catch (e) {
            debugPrint('JWT decode error: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  String _normalizePhone(String phoneNumber) => phoneNumber.replaceAll('+', '').replaceAll(' ', '');

  Future<void> register({
    required String phoneNumber,
    required String password,
    required String passwordConfirm,
    String? email,
    String language = 'ru',
  }) async {
    final body = {
      'phone_number': phoneNumber,
      'password': password,
      'password_confirm': passwordConfirm,
      'email': email,
      'language': language,
    }..removeWhere((key, value) => value == null);

    await _api.postJson('/auth/register/', body: body, auth: false);
  }

  Future<bool> sendOTP(String phoneNumber) async {
    try {
      await _api.postJson('/auth/send-sms/', body: {
        'phone_number': phoneNumber,
      }, auth: false);
      return true;
    } catch (e) {
      debugPrint('sendOTP error: $e');
      return false;
    }
  }

  Future<bool> verifyOTP(String phoneNumber, String code) async {
    try {
      await _api.postJson('/auth/verify-sms/', body: {
        'phone_number': phoneNumber,
        'code': code,
      }, auth: false);
      return true;
    } catch (e) {
      debugPrint('verifyOTP error: $e');
      return false;
    }
  }

  Future<bool> login({required String phoneNumber, required String password}) async {
    try {
      final username = _normalizePhone(phoneNumber);
      final data = await _api.postJson('/auth/token/', body: {
        'username': username,
        'password': password,
      }, auth: false);

      final access = data['access'] as String?;
      final refresh = data['refresh'] as String?;
      if (access == null || refresh == null) {
        throw ApiException('Invalid token response');
      }
      await _storage.saveTokens(access, refresh);

      // Create minimal user record; optionally extend by fetching profile later
      final now = DateTime.now();
      final user = User(
        id: username,
        phoneNumber: phoneNumber,
        name: 'Пользователь',
        preferredLanguage: 'ru',
        subscriptionTier: SubscriptionTier.free,
        createdAt: now,
        updatedAt: now,
      );
      await _storage.saveJson(_storage.userKey, user.toJson());
      _currentUser = user;
      return true;
    } catch (e) {
      debugPrint('login error: $e');
      return false;
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _storage.saveJson(_storage.userKey, user.toJson());
      _currentUser = user;
    } catch (e) {
      debugPrint('Error updating user: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _storage.remove(_storage.userKey);
      await _storage.clearTokens();
      _currentUser = null;
    } catch (e) {
      debugPrint('Error logging out: $e');
    }
  }
}
