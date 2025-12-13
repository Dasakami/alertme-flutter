import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:alertme/config/api_config.dart';
import 'package:alertme/services/storage_service.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic data;
  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final StorageService _storage = StorageService();

  String get _baseUrl {
    if (apiBaseUrl.isEmpty) {
      debugPrint('ApiClient: apiBaseUrl is empty. Please set lib/config/api_config.dart');
    }
    return apiBaseUrl;
  }

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await _storage.getString('access_token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    if (_baseUrl.isEmpty) {
      // Fallback to relative to allow proxying, but warn in logs.
      debugPrint('ApiClient: Using relative URL for $path');
      return Uri.parse(path);
    }
    final base = _baseUrl.endsWith('/') ? _baseUrl.substring(0, _baseUrl.length - 1) : _baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p').replace(queryParameters: query?.map((k, v) => MapEntry(k, '$v')));
  }

  Future<Map<String, dynamic>> getJson(String path, {Map<String, dynamic>? query, bool auth = true}) async {
    final res = await _send(() async => _client.get(_uri(path, query), headers: await _headers(auth: auth)), auth: auth);
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> postJson(String path, {Object? body, bool auth = true}) async {
    final res = await _send(
      () async => _client.post(_uri(path), headers: await _headers(auth: auth), body: jsonEncode(body ?? {})),
      auth: auth,
    );
    return _decodeJson(res);
  }

  Future<Map<String, dynamic>> putJson(String path, {Object? body, bool auth = true}) async {
    final res = await _send(
      () async => _client.put(_uri(path), headers: await _headers(auth: auth), body: jsonEncode(body ?? {})),
      auth: auth,
    );
    return _decodeJson(res);
  }

  Future<void> delete(String path, {bool auth = true}) async {
    await _send(() async => _client.delete(_uri(path), headers: await _headers(auth: auth)), auth: auth);
  }

  Future<http.Response> _send(Future<http.Response> Function() request, {required bool auth}) async {
    http.Response res = await request();
    if (res.statusCode == 401 && auth) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        res = await request();
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res;
    }

    String message = 'HTTP ${res.statusCode}';
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is Map && data['detail'] != null) message = data['detail'].toString();
    } catch (_) {
      // ignore
    }
    debugPrint('Api error: $message | Body: ${res.body}');
    throw ApiException(message, statusCode: res.statusCode, data: data);
  }

  Map<String, dynamic> _decodeJson(http.Response res) {
    try {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Decode error: $e');
      throw ApiException('Invalid JSON response', statusCode: res.statusCode);
    }
  }

  bool _isRefreshing = false;
  Future<bool> _refreshToken() async {
    if (_isRefreshing) {
      // simple wait loop
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        final token = await _storage.getString('access_token');
        if (token != null && token.isNotEmpty) return true;
      }
      return false;
    }

    _isRefreshing = true;
    try {
      final refresh = await _storage.getString('refresh_token');
      if (refresh == null || refresh.isEmpty) return false;
      final url = _uri('/auth/token/refresh/');
      final res = await _client.post(
        url,
        headers: await _headers(auth: false),
        body: jsonEncode({'refresh': refresh}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final newAccess = data['access'] as String?;
        if (newAccess != null) {
          await _storage.saveString('access_token', newAccess);
          return true;
        }
      } else {
        debugPrint('Refresh token failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('Refresh exception: $e');
    } finally {
      _isRefreshing = false;
    }
    await _storage.remove('access_token');
    await _storage.remove('refresh_token');
    return false;
  }
}
