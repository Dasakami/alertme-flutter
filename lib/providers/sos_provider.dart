import 'package:flutter/foundation.dart';
import 'package:alertme/models/sos_event.dart';
import 'package:alertme/models/emergency_contact.dart';
import 'package:alertme/services/sos_service.dart';

class SOSProvider with ChangeNotifier {
  final SOSService _sosService = SOSService();
  bool _isLoading = false;

  List<SOSEvent> get events => _sosService.events;
  SOSEvent? get activeEvent => _sosService.activeEvent;
  bool get hasActiveEvent => _sosService.hasActiveEvent;
  bool get isLoading => _isLoading;

  Future<void> loadEvents(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _sosService.loadEvents(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SOSEvent?> triggerSOS(String userId, List<EmergencyContact> contacts) async {
    _isLoading = true;
    notifyListeners();

    try {
      final event = await _sosService.triggerSOS(userId, contacts);
      return event;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelSOS() async {
    await _sosService.cancelSOS();
    notifyListeners();
  }

  Future<void> completeSOS() async {
    await _sosService.completeSOS();
    notifyListeners();
  }
}
