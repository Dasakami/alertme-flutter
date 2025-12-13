import 'package:flutter/foundation.dart';
import 'package:alertme/models/subscription.dart';
import 'package:alertme/services/api_client.dart';

class SubscriptionService {
  final ApiClient _api = ApiClient();
  List<SubscriptionPlan> _plans = [];
  UserSubscription? _currentSubscription;

  List<SubscriptionPlan> get plans => List.unmodifiable(_plans);
  UserSubscription? get currentSubscription => _currentSubscription;

  bool get hasActiveSubscription => 
      _currentSubscription != null && 
      _currentSubscription!.isActive;

  bool get isPremium => 
      hasActiveSubscription && 
      !_currentSubscription!.plan.isFree;

  Future<void> loadPlans() async {
    try {
      final data = await _api.getJson('/subscription-plans/', auth: false);
      
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
      
      _plans = results
          .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
          .toList();
          
      debugPrint('✅ Загружено ${_plans.length} планов');
    } catch (e) {
      debugPrint('❌ Ошибка загрузки планов: $e');
      _plans = [];
      rethrow;
    }
  }

  Future<void> loadCurrentSubscription() async {
    try {
      final data = await _api.getJson('/subscriptions/current/', auth: true);
      _currentSubscription = UserSubscription.fromJson(data);
      debugPrint('✅ Подписка загружена: ${_currentSubscription?.plan.name}');
    } catch (e) {
      debugPrint('❌ Ошибка загрузки подписки: $e');
      _currentSubscription = null;
    }
  }

  Future<UserSubscription> subscribe({
    required int planId,
    required String paymentPeriod,
    required String paymentMethod,
  }) async {
    try {
      final data = await _api.postJson('/subscriptions/', body: {
        'plan_id': planId,
        'payment_period': paymentPeriod,
        'payment_method': paymentMethod,
      }, auth: true);
      
      _currentSubscription = UserSubscription.fromJson(data);
      debugPrint('✅ Подписка оформлена: ${_currentSubscription?.plan.name}');
      return _currentSubscription!;
    } catch (e) {
      debugPrint('❌ Ошибка оформления подписки: $e');
      rethrow;
    }
  }

  Future<void> cancelSubscription() async {
    if (_currentSubscription == null) return;
    
    try {
      await _api.postJson(
        '/subscriptions/${_currentSubscription!.id}/cancel/',
        auth: true,
      );
      
      await loadCurrentSubscription();
      debugPrint('✅ Подписка отменена');
    } catch (e) {
      debugPrint('❌ Ошибка отмены подписки: $e');
      rethrow;
    }
  }

  Future<List<PaymentTransaction>> getPaymentHistory() async {
    try {
      final data = await _api.getJson('/payments/', auth: true);
      
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
          .map((e) => PaymentTransaction.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Ошибка загрузки истории платежей: $e');
      return [];
    }
  }

  SubscriptionPlan? getPlanById(int id) {
    try {
      return _plans.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearCache() {
    _plans = [];
    _currentSubscription = null;
  }
}