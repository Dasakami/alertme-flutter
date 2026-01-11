import 'package:flutter/foundation.dart';
import 'package:alertme/models/safety_timer.dart';
import 'package:alertme/services/storage_service.dart';

class TimerService {
  final StorageService _storage = StorageService();
  SafetyTimer? _activeTimer;

  SafetyTimer? get activeTimer => _activeTimer;
  bool get hasActiveTimer => _activeTimer != null && _activeTimer!.isActive && !_activeTimer!.isExpired;

  Future<void> loadTimer(String userId) async {
    try {
      final json = await _storage.getJson(_storage.safetyTimerKey);
      if (json != null) {
        final timer = SafetyTimer.fromJson(json);
        if (timer.userId == userId && timer.isActive && !timer.isExpired) {
          _activeTimer = timer;
        }
      }
    } catch (e) {
      debugPrint('Error loading timer: $e');
      _activeTimer = null;
    }
  }

  Future<SafetyTimer> startTimer(String userId, Duration duration) async {
    try {
      final now = DateTime.now();
      final timer = SafetyTimer(
        id: now.millisecondsSinceEpoch.toString(),
        userId: userId,
        duration: duration,
        startTime: now,
        expiryTime: now.add(duration),
        isActive: true,
      );

      _activeTimer = timer;
      await _storage.saveJson(_storage.safetyTimerKey, timer.toJson());
      
      if (duration.inSeconds < 60) {
        debugPrint('⏱️ Safety timer started for ${duration.inSeconds} seconds');
      } else {
        debugPrint('⏱️ Safety timer started for ${duration.inMinutes} minutes');
      }
      
      return timer;
    } catch (e) {
      debugPrint('Error starting timer: $e');
      rethrow;
    }
  }

  Future<void> cancelTimer() async {
    try {
      if (_activeTimer != null) {
        final updated = _activeTimer!.copyWith(isActive: false);
        _activeTimer = null;
        await _storage.saveJson(_storage.safetyTimerKey, updated.toJson());
        debugPrint('✅ Safety timer cancelled');
      }
    } catch (e) {
      debugPrint('Error cancelling timer: $e');
    }
  }

  Future<void> completeTimer() async {
    try {
      if (_activeTimer != null) {
        final updated = _activeTimer!.copyWith(isActive: false);
        _activeTimer = null;
        await _storage.saveJson(_storage.safetyTimerKey, updated.toJson());
        debugPrint('✅ Safety timer completed');
      }
    } catch (e) {
      debugPrint('Error completing timer: $e');
    }
  }
}