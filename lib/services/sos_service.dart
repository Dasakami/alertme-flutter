import 'package:flutter/foundation.dart';
import 'package:alertme/models/sos_alert.dart';
import 'package:alertme/services/api_client.dart';

class SOSService {
  final ApiClient _api = ApiClient();
  List<SOSAlertModel> _alerts = [];
  SOSAlertModel? _activeAlert;

  List<SOSAlertModel> get alerts => List.unmodifiable(_alerts);
  SOSAlertModel? get activeAlert => _activeAlert;
  bool get hasActiveAlert => _activeAlert != null;

  Future<void> loadAlerts() async {
    try {
      final data = await _api.getJson('/sos-alerts/', auth: true);
      
      List<dynamic> results; // ИСПРАВЛЕНО
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

  Future<SOSAlertModel> triggerSOS({
    required double latitude,
    required double longitude,
    double? locationAccuracy,
    String? address,
    String activationMethod = 'button',
    String? notes,
  }) async {
    try {
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
      return alert;
    } catch (e) {
      debugPrint('❌ Ошибка активации SOS: $e');
      rethrow;
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
      
      List<dynamic> results; // ИСПРАВЛЕНО
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