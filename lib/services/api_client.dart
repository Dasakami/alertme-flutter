import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:alertme/config/api_config.dart';
import 'package:alertme/services/storage_service.dart';
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, dynamic>? errors;
  
  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      final errorMessages = <String>[];
      errors!.forEach((key, value) {
        if (value is List) {
          errorMessages.add('$key: ${value.join(", ")}');
        } else {
          errorMessages.add('$key: $value');
        }
      });
      return errorMessages.join('\n');
    }
    return message;
  }
}
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final StorageService _storage = StorageService();
  String get _baseUrl {
    if (apiBaseUrl.isEmpty) {
      debugPrint('⚠️ ApiClient: apiBaseUrl пустой. Проверьте lib/config/api_config.dart');
      return '';
    }
    return apiBaseUrl.endsWith('/') 
      ? apiBaseUrl.substring(0, apiBaseUrl.length - 1) 
      : apiBaseUrl;
  }
  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (auth) {
      final token = await _storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  Uri _uri(String path, [Map<String, dynamic>? query]) {
    if (_baseUrl.isEmpty) {
      debugPrint('⚠️ Используется относительный URL: $path');
      return Uri.parse(path);
    }
    final fullUrl = '$_baseUrl$path';
    return Uri.parse(fullUrl).replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v'))
    );
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? query, 
    bool auth = true
  }) async {
    final res = await _send(
      () async => _client.get(
        _uri(path, query), 
        headers: await _headers(auth: auth)
      ),
      auth: auth,
    );
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Object? body, 
    bool auth = true
  }) async {
    final res = await _send(
      () async => _client.post(
        _uri(path),
        headers: await _headers(auth: auth),
        body: jsonEncode(body ?? {}),
      ),
      auth: auth,
    );
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Object? body, 
    bool auth = true
  }) async {
    final res = await _send(
      () async => _client.put(
        _uri(path),
        headers: await _headers(auth: auth),
        body: jsonEncode(body ?? {}),
      ),
      auth: auth,
    );
    return _decodeJson(res);
  }
  Future<Map<String, dynamic>> patchJson(
    String path, {
    Object? body, 
    bool auth = true
  }) async {
    final res = await _send(
      () async => _client.patch(
        _uri(path),
        headers: await _headers(auth: auth),
        body: jsonEncode(body ?? {}),
      ),
      auth: auth,
    );
    return _decodeJson(res);
  }
  Future<void> delete(String path, {bool auth = true}) async {
    await _send(
      () async => _client.delete(
        _uri(path), 
        headers: await _headers(auth: auth)
      ),
      auth: auth,
    );
  }

  bool _isRefreshing = false;
  Future<http.Response> _send(
    Future<http.Response> Function() request, 
    {required bool auth}
  ) async {
    try {
      http.Response res = await request();
      if (res.statusCode == 401 && auth && !_isRefreshing) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          res = await request();
        }
      }
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return res;
      }
      String message = 'HTTP ${res.statusCode}';
      Map<String, dynamic>? errors;
      
      try {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        
        if (data is Map<String, dynamic>) {
          if (data['detail'] != null) {
            message = data['detail'].toString();
          } else if (data['error'] != null) {
            message = data['error'].toString();
          } else {
            errors = data.cast<String, dynamic>();
            final errorList = <String>[];
            
            errors.forEach((key, value) {
              if (value is List) {
                errorList.add('$key: ${value.join(", ")}');
              } else {
                errorList.add('$key: $value');
              }
            });
            
            if (errorList.isNotEmpty) {
              message = errorList.join('\n');
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Ошибка парсинга ответа: $e');
      }
      debugPrint('❌ API Error ${res.statusCode}: $message');
      debugPrint('URL: ${res.request?.url}');
      debugPrint('Response: ${res.body}');
      
      throw ApiException(
        message, 
        statusCode: res.statusCode, 
        errors: errors,
      );
      
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('❌ Ошибка сети: $e');
      throw ApiException('Ошибка сети: $e');
    }
  }
  Map<String, dynamic> _decodeJson(http.Response res) {
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'data': decoded};
    } catch (e) {
      debugPrint('❌ Ошибка декодирования JSON: $e');
      debugPrint('Response body: ${res.body}');
      throw ApiException(
        'Неверный формат ответа сервера', 
        statusCode: res.statusCode
      );
    }
  }
  Future<bool> _refreshToken() async {
    if (_isRefreshing) {
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        final token = await _storage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          return true;
        }
      }
      return false;
    }

    _isRefreshing = true;
    
    try {
      final refresh = await _storage.getRefreshToken();
      
      if (refresh == null || refresh.isEmpty) {
        debugPrint('❌ Refresh токен отсутствует');
        return false;
      }

      final res = await _client.post(
        _uri('/auth/token/refresh/'),
        headers: await _headers(auth: false),
        body: jsonEncode({'refresh': refresh}),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final newAccess = data['access'] as String?;
        
        if (newAccess != null) {
          await _storage.saveAccessToken(newAccess);
          debugPrint('✅ Токен обновлен');
          return true;
        }
      }
      
      debugPrint('❌ Не удалось обновить токен: ${res.statusCode}');
      await _storage.clearTokens();
      return false;
      
    } catch (e) {
      debugPrint('❌ Ошибка обновления токена: $e');
      await _storage.clearTokens();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }
}