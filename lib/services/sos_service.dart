import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:alertme/models/sos_alert.dart';
import 'package:alertme/services/api_client.dart';
import 'package:alertme/services/storage_service.dart';
import 'package:alertme/config/api_config.dart';

class SOSService {
  final ApiClient _api = ApiClient();
  final StorageService _storage = StorageService();
  
  List<SOSAlertModel> _alerts = [];
  SOSAlertModel? _activeAlert;

  List<SOSAlertModel> get alerts => List.unmodifiable(_alerts);
  SOSAlertModel? get activeAlert => _activeAlert;
  bool get hasActiveAlert => _activeAlert != null;

  Future<void> loadAlerts() async {
    try {
      final data = await _api.getJson('/sos-alerts/', auth: true);
      
      List<dynamic> results;
      if (data is List) {
        results = data as List<dynamic>;
      } else if (data['results'] is List) {
        results = data['results'] as List<dynamic>;
      } else if (data['data'] is List) {
        results = data['data'] as List<dynamic>;
      } else {
        results = [];
      }
      
      _alerts = results
          .map((e) => SOSAlertModel.fromJson(e as Map<String, dynamic>))
          .toList();
      
      _activeAlert = _alerts
          .where((a) => a.isActive)
          .lastOrNull;
          
      debugPrint('✅ Загружено ${_alerts.length} SOS сигналов');
    } catch (e) {
      debugPrint('❌ Ошибка загрузки SOS: $e');
      _alerts = [];
      rethrow;
    }
  }

  Future<SOSAlertModel?> getActiveAlert() async {
    try {
      final data = await _api.getJson('/sos-alerts/active/', auth: true);
      _activeAlert = SOSAlertModel.fromJson(data);
      return _activeAlert;
    } catch (e) {
      debugPrint('❌ Нет активного SOS сигнала');
      _activeAlert = null;
      return null;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Активация SOS с аудио файлом
  Future<SOSAlertModel?> triggerSOS({
    required double latitude,
    required double longitude,
    double? locationAccuracy,
    String? address,
    String activationMethod = 'button',
    String? notes,
    String? audioPath,  // ← ИСПРАВЛЕНО: название параметра
  }) async {
    try {
      // 1. Создаем SOS без медиа
      final data = await _api.postJson('/sos-alerts/', body: {
        'latitude': latitude,
        'longitude': longitude,
        'location_accuracy': locationAccuracy,
        'address': address,
        'activation_method': activationMethod,
        'notes': notes,
      }, auth: true);
      
      final alert = SOSAlertModel.fromJson(data);
      _activeAlert = alert;
      _alerts.insert(0, alert);
      
      debugPrint('✅ SOS активирован: ${alert.id}');
      
      // 2. Загружаем аудио если есть
      if (audioPath != null) {
        final audioUploaded = await uploadAudio(alert.id, audioPath);
        if (audioUploaded) {
          debugPrint('✅ Аудио загружено для SOS ${alert.id}');
        } else {
          debugPrint('⚠️ Не удалось загрузить аудио');
        }
      }
      
      return alert;
    } catch (e) {
      debugPrint('❌ Ошибка активации SOS: $e');
      rethrow;
    }
  }

  /// ✅ ИСПРАВЛЕНО: Загрузка аудио файла
  Future<bool> uploadAudio(int sosId, String audioPath) async {
    try {
      final file = File(audioPath);
      
      if (!await file.exists()) {
        debugPrint('❌ Аудио файл не найден: $audioPath');
        return false;
      }

      // ✅ ИСПРАВЛЕНО: Получаем токен через StorageService
      final token = await _storage.getAccessToken();
      if (token == null) {
        debugPrint('❌ Токен отсутствует');
        return false;
      }

      // ✅ ИСПРАВЛЕНО: Используем apiBaseUrl из конфига
      final uri = Uri.parse('$apiBaseUrl/sos-alerts/$sosId/upload_audio/');
      final request = http.MultipartRequest('POST', uri);
      
      // Добавляем заголовки
      request.headers['Authorization'] = 'Bearer $token';
      
      // Добавляем файл
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioPath,
          filename: 'sos_audio.aac',
        ),
      );

      debugPrint('📤 Загрузка аудио на сервер: $uri');
      
      // Отправляем
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        debugPrint('✅ Аудио успешно загружено');
        debugPrint('Response: $responseBody');
        return true;
      } else {
        debugPrint('❌ Ошибка загрузки аудио: ${response.statusCode}');
        debugPrint('Response: $responseBody');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки аудио: $e');
      return false;
    }
  }

  Future<SOSAlertModel> updateStatus(int alertId, String status) async {
    try {
      final data = await _api.postJson(
        '/sos-alerts/$alertId/update_status/',
        body: {'status': status},
        auth: true,
      );
      
      final updated = SOSAlertModel.fromJson(data);
      final index = _alerts.indexWhere((a) => a.id == alertId);
      
      if (index != -1) {
        _alerts[index] = updated;
      }
      
      if (_activeAlert?.id == alertId && !updated.isActive) {
        _activeAlert = null;
      }
      
      debugPrint('✅ Статус SOS обновлен: $status');
      return updated;
    } catch (e) {
      debugPrint('❌ Ошибка обновления статуса: $e');
      rethrow;
    }
  }

  Future<void> cancelSOS() async {
    if (_activeAlert != null) {
      await updateStatus(_activeAlert!.id, 'cancelled');
      debugPrint('✅ SOS отменен');
    }
  }

  Future<void> resolveSOS() async {
    if (_activeAlert != null) {
      await updateStatus(_activeAlert!.id, 'resolved');
      debugPrint('✅ SOS завершен');
    }
  }

  Future<void> markAsFalseAlarm() async {
    if (_activeAlert != null) {
      await updateStatus(_activeAlert!.id, 'false_alarm');
      debugPrint('✅ SOS отмечен как ложная тревога');
    }
  }

  Future<List<SOSAlertModel>> getHistory() async {
    try {
      final data = await _api.getJson('/sos-alerts/history/', auth: true);
      
      List<dynamic> results;
      if (data is List) {
        results = data as List<dynamic>;
      } else if (data['results'] is List) {
        results = data['results'] as List<dynamic>;
      } else if (data['data'] is List) {
        results = data['data'] as List<dynamic>;
      } else {
        results = [];
      }
      
      return results
          .map((e) => SOSAlertModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Ошибка загрузки истории: $e');
      return [];
    }
  }

  void clearCache() {
    _alerts = [];
    _activeAlert = null;
  }
}