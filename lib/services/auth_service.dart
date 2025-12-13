import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:alertme/models/user.dart';
import 'package:alertme/services/storage_service.dart';
import 'package:alertme/services/api_client.dart';

class AuthService {
  final StorageService _storage = StorageService();
  final ApiClient _api = ApiClient();

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<void> init() async {
    await loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    try {
      final json = await _storage.getJson(_storage.userKey);
      
      if (json != null) {
        _currentUser = UserModel.fromJson(json);
        debugPrint('✅ Пользователь загружен из кэша: ${_currentUser?.phoneNumber}');
      } else {
        final token = await _storage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          await loadUserProfile();
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки пользователя: $e');
    }
  }

  Future<void> loadUserProfile() async {
    try {
      final data = await _api.getJson('/users/me/', auth: true);
      final user = UserModel.fromJson(data);
      
      await _storage.saveJson(_storage.userKey, user.toJson());
      _currentUser = user;
      
      debugPrint('✅ Профиль загружен: ${user.phoneNumber}');
    } catch (e) {
      debugPrint('❌ Ошибка загрузки профиля: $e');
      rethrow;
    }
  }

  String _normalizePhone(String phone) {
    return phone
        .replaceAll('+', '')
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '');
  }

  Future<void> register({
    required String phoneNumber,
    required String password,
    required String passwordConfirm,
    String? email,
    String language = 'ru',
  }) async {
    if (!phoneNumber.startsWith('+')) {
      throw ApiException('Номер телефона должен начинаться с +');
    }
    
    if (password.length < 6) {
      throw ApiException('Пароль должен быть минимум 6 символов');
    }
    
    if (password != passwordConfirm) {
      throw ApiException('Пароли не совпадают');
    }

    final body = <String, dynamic>{
      'phone_number': phoneNumber,
      'password': password,
      'password_confirm': passwordConfirm,
      'language': language,
    };

    if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }

    try {
      final data = await _api.postJson('/auth/register/', body: body, auth: false);
      
      if (data['tokens'] != null) {
        final tokens = data['tokens'] as Map<String, dynamic>;
        await _storage.saveTokens(
          tokens['access'] as String,
          tokens['refresh'] as String,
        );
        
        if (data['user'] != null) {
          final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
          await _storage.saveJson(_storage.userKey, user.toJson());
          _currentUser = user;
        }
      }
      
      debugPrint('✅ Регистрация успешна: $phoneNumber');
    } catch (e) {
      debugPrint('❌ Ошибка регистрации: $e');
      rethrow;
    }
  }

  Future<bool> sendOTP(String phoneNumber) async {
    try {
      await _api.postJson('/auth/send-sms/', body: {
        'phone_number': phoneNumber,
      }, auth: false);
      
      debugPrint('✅ SMS код отправлен: $phoneNumber');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка отправки SMS: $e');
      return false;
    }
  }

  Future<bool> verifyOTP(String phoneNumber, String code) async {
    try {
      final data = await _api.postJson('/auth/verify-sms/', body: {
        'phone_number': phoneNumber,
        'code': code,
      }, auth: false);

      if (data['tokens'] != null) {
        final tokens = data['tokens'] as Map<String, dynamic>;
        await _storage.saveTokens(
          tokens['access'] as String,
          tokens['refresh'] as String,
        );
        
        if (data['user'] != null) {
          final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
          await _storage.saveJson(_storage.userKey, user.toJson());
          _currentUser = user;
        }
      }

      debugPrint('✅ SMS код подтвержден');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка верификации SMS: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ИСПРАВЛЕН МЕТОД LOGIN
  // ═══════════════════════════════════════════════════════════════
  Future<bool> login({
    required String phoneNumber, 
    required String password
  }) async {
    try {
      // Нормализуем номер (убираем +)
      final normalizedPhone = _normalizePhone(phoneNumber);
      
      debugPrint('🔐 Попытка входа...');
      debugPrint('📱 Оригинальный номер: $phoneNumber');
      debugPrint('📱 Нормализованный: $normalizedPhone');
      
      // Django JWT ожидает username и password
      final body = {
        'username': normalizedPhone, // БЕЗ +
        'password': password,
      };
      
      debugPrint('📤 Отправляем: $body');
      
      final data = await _api.postJson('/auth/token/', body: body, auth: false);

      final access = data['access'] as String?;
      final refresh = data['refresh'] as String?;
      
      if (access == null || refresh == null) {
        throw ApiException('Неверный ответ сервера');
      }
      
      // Сохраняем токены
      await _storage.saveTokens(access, refresh);
      debugPrint('✅ Токены сохранены');
      
      // Создаем временного пользователя
      final now = DateTime.now();
      final tempUser = UserModel(
        id: 0, // Будет заменен после загрузки профиля
        phoneNumber: phoneNumber,
        language: 'ru',
        isPhoneVerified: true,
        createdAt: now,
      );
      
      await _storage.saveJson(_storage.userKey, tempUser.toJson());
      _currentUser = tempUser;
      
      // Пробуем загрузить полный профиль
      try {
        await loadUserProfile();
      } catch (e) {
        debugPrint('⚠️ Не удалось загрузить полный профиль: $e');
        // Но продолжаем с временным пользователем
      }
      
      debugPrint('✅ Вход выполнен: $phoneNumber');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка входа: $e');
      return false;
    }
  }

  Future<void> updateProfile({
    String? email,
    String? firstName,
    String? lastName,
    String? language,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (email != null) body['email'] = email;
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (language != null) body['language'] = language;

      final data = await _api.patchJson('/users/me/', body: body, auth: true);

      final user = UserModel.fromJson(data);
      await _storage.saveJson(_storage.userKey, user.toJson());
      _currentUser = user;

      debugPrint('✅ Профиль обновлен на сервере');
    } catch (e) {
      debugPrint('❌ Ошибка обновления профиля: $e');
      rethrow;
    }
  }

  Future<void> updateFCMToken(String fcmToken) async {
    try {
      await _api.postJson(
        '/users/update_fcm_token/',
        body: {'fcm_token': fcmToken},
        auth: true,
      );
      debugPrint('✅ FCM токен обновлен');
    } catch (e) {
      debugPrint('❌ Ошибка обновления FCM токена: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _storage.remove(_storage.userKey);
      await _storage.clearTokens();
      _currentUser = null;
      debugPrint('✅ Выход выполнен');
    } catch (e) {
      debugPrint('❌ Ошибка выхода: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _api.delete('/users/delete_account/', auth: true);
      await logout();
      debugPrint('✅ Аккаунт удален');
    } catch (e) {
      debugPrint('❌ Ошибка удаления аккаунта: $e');
      rethrow;
    }
  }
}