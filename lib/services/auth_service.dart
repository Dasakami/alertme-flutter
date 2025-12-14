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
      
      // Регистрация прошла, но нужно подтвердить номер
      debugPrint('✅ Регистрация успешна: $phoneNumber');
      debugPrint('⚠️ Требуется подтверждение номера');
    } catch (e) {
      debugPrint('❌ Ошибка регистрации: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    try {
      final data = await _api.postJson('/auth/send-sms/', body: {
        'phone_number': phoneNumber,
      }, auth: false);
      
      debugPrint('✅ SMS код отправлен: $phoneNumber');
      debugPrint('🔑 Тестовый код: ${data['code']}'); // ДЛЯ ТЕСТИРОВАНИЯ
      
      return data;
    } catch (e) {
      debugPrint('❌ Ошибка отправки SMS: $e');
      rethrow;
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
  // АВТОРИЗАЦИЯ ПО ТЕЛЕФОНУ (без username)
  // ═══════════════════════════════════════════════════════════════
  Future<bool> login({
    required String phoneNumber, 
    required String password
  }) async {
    try {
      debugPrint('🔐 Попытка входа...');
      debugPrint('📱 Номер: $phoneNumber');
      
      // Отправляем phone_number и password
      final body = {
        'phone_number': phoneNumber,
        'password': password,
      };
      
      debugPrint('📤 Отправляем: $body');
      
      final data = await _api.postJson('/auth/login/', body: body, auth: false);

      final tokens = data['tokens'] as Map<String, dynamic>?;
      final access = tokens?['access'] as String?;
      final refresh = tokens?['refresh'] as String?;
      
      if (access == null || refresh == null) {
        throw ApiException('Неверный ответ сервера');
      }
      
      // Сохраняем токены
      await _storage.saveTokens(access, refresh);
      debugPrint('✅ Токены сохранены');
      
      // Сохраняем пользователя
      if (data['user'] != null) {
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        await _storage.saveJson(_storage.userKey, user.toJson());
        _currentUser = user;
        debugPrint('✅ Пользователь сохранен');
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