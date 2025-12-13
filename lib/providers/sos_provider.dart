import 'package:flutter/foundation.dart';
import 'package:alertme/models/sos_alert.dart';
import 'package:alertme/services/sos_service.dart';

class SOSProvider with ChangeNotifier {
  final SOSService _service = SOSService();
  bool _isLoading = false;
  String? _error;

  List<SOSAlertModel> get alerts => _service.alerts;
  SOSAlertModel? get activeAlert => _service.activeAlert;
  bool get hasActiveAlert => _service.hasActiveAlert;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAlerts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.loadAlerts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SOSAlertModel?> triggerSOS({
    required double latitude,
    required double longitude,
    double? locationAccuracy,
    String? address,
    String activationMethod = 'button',
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final alert = await _service.triggerSOS(
        latitude: latitude,
        longitude: longitude,
        locationAccuracy: locationAccuracy,
        address: address,
        activationMethod: activationMethod,
        notes: notes,
      );
      _isLoading = false;
      notifyListeners();
      return alert;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> cancelSOS() async {
    try {
      await _service.cancelSOS();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> resolveSOS() async {
    try {
      await _service.resolveSOS();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAsFalseAlarm() async {
    try {
      await _service.markAsFalseAlarm();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}