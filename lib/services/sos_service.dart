import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:alertme/models/sos_alert.dart';
import 'package:alertme/services/storage_service.dart';
import 'package:alertme/config/api_config.dart';

class SOSService {
  final StorageService _storage = StorageService();
  
  List<SOSAlertModel> _alerts = [];
  SOSAlertModel? _activeAlert;

  List<SOSAlertModel> get alerts => List.unmodifiable(_alerts);
  SOSAlertModel? get activeAlert => _activeAlert;
  bool get hasActiveAlert => _activeAlert != null;

  Future<void> loadAlerts() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) return;

      final uri = Uri.parse('$apiBaseUrl/sos-alerts/');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        List<dynamic> results;
        if (data is List) {
          results = data;
        } else if (data['results'] is List) {
          results = data['results'];
        } else {
          results = [];
        }

        _alerts = results
            .map((e) => SOSAlertModel.fromJson(e as Map<String, dynamic>))
            .toList();

        _activeAlert = _alerts.where((a) => a.isActive).lastOrNull;
        
        debugPrint('✅ Загружено ${_alerts.length} SOS алертов');
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки SOS: $e');
    }
  }
  Future<SOSAlertModel?> triggerSOS({
    required double latitude,
    required double longitude,
    double? locationAccuracy,
    String? address,
    String activationMethod = 'button',
    String? notes,
    String? audioPath,
  }) async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        debugPrint('❌ Токен отсутствует');
        throw Exception('Требуется авторизация');
      }
      final uri = Uri.parse('$apiBaseUrl/sos-alerts/');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      
      if (locationAccuracy != null) {
        request.fields['location_accuracy'] = locationAccuracy.toString();
      }
      
      if (address != null && address.isNotEmpty) {
        request.fields['address'] = address;
      }
      
      request.fields['activation_method'] = activationMethod;
      
      if (notes != null && notes.isNotEmpty) {
        request.fields['notes'] = notes;
      }

      if (audioPath != null) {
        final audioFile = File(audioPath);
        
        if (await audioFile.exists()) {
          debugPrint('📎 Прикрепляем аудио: $audioPath');
          
          request.files.add(
            await http.MultipartFile.fromPath(
              'audio_file', 
              audioPath,
              filename: 'sos_audio.aac',
            ),
          );
          
          final fileSize = await audioFile.length();
          debugPrint('📁 Размер аудио: ${fileSize / 1024} KB');
        } else {
          debugPrint('⚠️ Аудио файл не найден: $audioPath');
        }
      }

      debugPrint('📤 Отправка SOS на сервер...');
      debugPrint('📍 Координаты: $latitude, $longitude');
      debugPrint('🎤 Аудио: ${audioPath != null ? "Да" : "Нет"}');
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      debugPrint('📥 Ответ сервера: ${response.statusCode}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        
        final alert = SOSAlertModel.fromJson(data);
        _activeAlert = alert;
        _alerts.insert(0, alert);
        
        debugPrint('✅ SOS создан успешно: ID ${alert.id}');
        debugPrint('🎤 Аудио загружено: ${alert.audioFile != null}');
        
        return alert;
      } else {
        debugPrint('❌ Ошибка создания SOS: ${response.statusCode}');
        debugPrint('Response: $responseBody');
        throw Exception('Ошибка создания SOS: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Ошибка активации SOS: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> cancelSOS() async {
    if (_activeAlert != null) {
      try {
        final token = await _storage.getAccessToken();
        if (token == null) return;

        final uri = Uri.parse('$apiBaseUrl/sos-alerts/${_activeAlert!.id}/update_status/');
        final response = await http.post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'status': 'cancelled'}),
        );

        if (response.statusCode == 200) {
          _activeAlert = null;
          debugPrint('✅ SOS отменен');
        }
      } catch (e) {
        debugPrint('❌ Ошибка отмены SOS: $e');
      }
    }
  }
  Future<void> resolveSOS() async {
    if (_activeAlert != null) {
      try {
        final token = await _storage.getAccessToken();
        if (token == null) return;

        final uri = Uri.parse('$apiBaseUrl/sos-alerts/${_activeAlert!.id}/update_status/');
        final response = await http.post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'status': 'resolved'}),
        );

        if (response.statusCode == 200) {
          _activeAlert = null;
          debugPrint('✅ SOS завершен');
        }
      } catch (e) {
        debugPrint('❌ Ошибка завершения SOS: $e');
      }
    }
  }

  Future<void> markAsFalseAlarm() async {
    if (_activeAlert != null) {
      try {
        final token = await _storage.getAccessToken();
        if (token == null) return;

        final uri = Uri.parse('$apiBaseUrl/sos-alerts/${_activeAlert!.id}/update_status/');
        final response = await http.post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'status': 'false_alarm'}),
        );

        if (response.statusCode == 200) {
          _activeAlert = null;
          debugPrint('✅ SOS отмечен как ложная тревога');
        }
      } catch (e) {
        debugPrint('❌ Ошибка: $e');
      }
    }
  }

  void clearCache() {
    _alerts = [];
    _activeAlert = null;
  }
}