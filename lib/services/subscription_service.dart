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
          
      debugPrint('Загружено ${_plans.length} планов');
    } catch (e) {
      debugPrint(' Ошибка загрузки планов: $e');
      _plans = [];
      rethrow;
    }
  }

  Future<void> loadCurrentSubscription() async {
    try {
      debugPrint('Загрузка подписки...');
      
      final data = await _api.getJson('/subscriptions/current/', auth: true);
      
      debugPrint(' Получен ответ: ${data.keys}');
      
      final isPremium = data['is_premium'] as bool? ?? false;
      final status = data['status'] as String?;
      
      if (isPremium && data['id'] != null) {
        _currentSubscription = UserSubscription(
          id: data['id'] as int,
          plan: SubscriptionPlan.fromJson(data['plan'] as Map<String, dynamic>),
          status: status ?? 'active',
          paymentPeriod: data['payment_period'] as String? ?? 'monthly',
          startDate: DateTime.parse(data['end_date'] as String).subtract(const Duration(days: 30)),
          endDate: DateTime.parse(data['end_date'] as String),
          autoRenew: data['auto_renew'] as bool? ?? false,
          daysRemaining: data['days_remaining'] as int? ?? 0,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        debugPrint('Premium подписка: ${_currentSubscription?.plan.name}');
      } else {
        _currentSubscription = null;
        debugPrint('Free план');
      }
    } catch (e) {
      debugPrint('Ошибка загрузки подписки: $e');
      _currentSubscription = null;
    }
  }

  Future<bool> activateCode(String code) async {
    try {
      debugPrint('🔑 Активация кода: $code');
      
      final data = await _api.postJson(
        '/activation-codes/activate/',
        body: {'code': code},
        auth: true,
      );
      
      debugPrint('📦 Ответ сервера: $data');
      
      final success = data['success'] as bool? ?? false;
      
      if (!success) {
        final errorMessage = data['error'] as String? ?? 'Неизвестная ошибка';
        throw Exception(errorMessage);
      }
      if (data['subscription'] != null) {
        final subData = data['subscription'] as Map<String, dynamic>;
        
        _currentSubscription = UserSubscription(
          id: subData['id'] as int,
          plan: SubscriptionPlan(
            id: 2,
            name: subData['plan'] as String? ?? 'Premium',
            planType: 'personal_premium',
            priceMonthly: 100,
            maxContacts: 999,
            geozonesEnabled: true,
            locationHistoryEnabled: true,
          ),
          status: subData['status'] as String,
          paymentPeriod: 'monthly',
          startDate: DateTime.now(),
          endDate: DateTime.parse(subData['end_date'] as String),
          autoRenew: false,
          daysRemaining: subData['days_remaining'] as int? ?? 0,
          isActive: subData['is_premium'] as bool? ?? true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      
      debugPrint('✅ Код активирован успешно');
      return true;
      
    } catch (e) {
      debugPrint('❌ Ошибка активации кода: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> checkCode(String code) async {
    try {
      final data = await _api.postJson(
        '/activation-codes/check/',
        body: {'code': code},
        auth: true,
      );
      
      return data;
    } catch (e) {
      debugPrint('❌ Ошибка проверки кода: $e');
      return null;
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