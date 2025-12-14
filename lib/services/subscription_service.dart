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
      
      List<dynamic> results = [];
      
      if (data is List) {
        results = data as List<dynamic>;
      } else if (data is Map<String, dynamic>) {
        if (data['results'] != null && data['results'] is List) {
          results = data['results'] as List<dynamic>;
        } else if (data['data'] != null && data['data'] is List) {
          results = data['data'] as List<dynamic>;
        }
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
      
      // ИСПРАВЛЕНИЕ: проверяем, что вернулся объект подписки
      if (data['detail'] != null || data['plan'] == 'free') {
        // Нет активной подписки
        _currentSubscription = null;
        debugPrint('ℹ️ Нет активной подписки (Free план)');
        return;
      }
      
      // ЗАЩИТА: Проверяем обязательные поля перед парсингом
      if (data['id'] != null && data['plan'] != null) {
        _currentSubscription = UserSubscription.fromJson(data);
        debugPrint('✅ Подписка загружена: ${_currentSubscription?.plan.name}');
      } else {
        _currentSubscription = null;
        debugPrint('⚠️ Неполные данные подписки');
      }
    } catch (e) {
      debugPrint('❌ Ошибка загрузки подписки: $e');
      _currentSubscription = null;
      // НЕ пробрасываем ошибку дальше - это не критично
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
      
      List<dynamic> results = [];
      
      if (data is List) {
        results = data as List<dynamic>;
      } else if (data is Map<String, dynamic>) {
        if (data['results'] != null && data['results'] is List) {
          results = data['results'] as List<dynamic>;
        } else if (data['data'] != null && data['data'] is List) {
          results = data['data'] as List<dynamic>;
        }
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