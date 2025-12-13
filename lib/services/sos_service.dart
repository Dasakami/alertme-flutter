import 'package:flutter/foundation.dart';
import 'package:alertme/models/sos_event.dart';
import 'package:alertme/models/emergency_contact.dart';
import 'package:alertme/services/storage_service.dart';
import 'package:alertme/services/location_service.dart';

class SOSService {
  final StorageService _storage = StorageService();
  final LocationService _locationService = LocationService();
  List<SOSEvent> _events = [];
  SOSEvent? _activeEvent;

  List<SOSEvent> get events => List.unmodifiable(_events);
  SOSEvent? get activeEvent => _activeEvent;
  bool get hasActiveEvent => _activeEvent != null;

  Future<void> loadEvents(String userId) async {
    try {
      final jsonList = await _storage.getJsonList(_storage.sosEventsKey);
      final List<SOSEvent> loadedEvents = [];
      
      for (final json in jsonList) {
        try {
          final event = SOSEvent.fromJson(json);
          if (event.userId == userId) {
            loadedEvents.add(event);
          }
        } catch (e) {
          debugPrint('Skipping corrupted event: $e');
        }
      }
      
      _events = loadedEvents;
      _activeEvent = _events.where((e) => e.status == SOSStatus.active).lastOrNull;
      await _saveEvents();
    } catch (e) {
      debugPrint('Error loading events: $e');
      _events = [];
      _activeEvent = null;
    }
  }

  Future<SOSEvent?> triggerSOS(String userId, List<EmergencyContact> contacts) async {
    try {
      final location = await _locationService.getCurrentLocation();
      
      final event = SOSEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        timestamp: DateTime.now(),
        location: location,
        status: SOSStatus.active,
        notifiedContacts: contacts.map((c) => c.id).toList(),
      );

      _activeEvent = event;
      _events.add(event);
      await _saveEvents();

      await Future.delayed(const Duration(seconds: 2));
      debugPrint('SOS triggered! Notifying ${contacts.length} contacts...');
      
      for (final contact in contacts) {
        debugPrint('Notified ${contact.name} at ${contact.phoneNumber}');
        debugPrint('Location: ${location?.mapUrl ?? "Unknown"}');
      }

      return event;
    } catch (e) {
      debugPrint('Error triggering SOS: $e');
      return null;
    }
  }

  Future<void> cancelSOS() async {
    try {
      if (_activeEvent != null) {
        final updated = _activeEvent!.copyWith(status: SOSStatus.cancelled);
        final index = _events.indexWhere((e) => e.id == _activeEvent!.id);
        if (index != -1) {
          _events[index] = updated;
        }
        _activeEvent = null;
        await _saveEvents();
        debugPrint('SOS cancelled');
      }
    } catch (e) {
      debugPrint('Error cancelling SOS: $e');
    }
  }

  Future<void> completeSOS() async {
    try {
      if (_activeEvent != null) {
        final updated = _activeEvent!.copyWith(status: SOSStatus.completed);
        final index = _events.indexWhere((e) => e.id == _activeEvent!.id);
        if (index != -1) {
          _events[index] = updated;
        }
        _activeEvent = null;
        await _saveEvents();
        debugPrint('SOS completed');
      }
    } catch (e) {
      debugPrint('Error completing SOS: $e');
    }
  }

  Future<void> _saveEvents() async {
    try {
      final jsonList = _events.map((e) => e.toJson()).toList();
      await _storage.saveJsonList(_storage.sosEventsKey, jsonList);
    } catch (e) {
      debugPrint('Error saving events: $e');
    }
  }
}