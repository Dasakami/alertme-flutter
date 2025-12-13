import 'package:flutter/foundation.dart';
import 'package:alertme/models/subscription.dart';
import 'package:alertme/services/api_client.dart';

class SubscriptionService {
  SubscriptionService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();
  final ApiClient _api;

  static const String _plansPath = '/api/subscription-plans/';
  static const String _currentPath = '/api/subscription/';
  static const String _subscribePath = '/api/subscribe/';

  Future<List<SubscriptionPlan>> getPlans() async {
    try {
      final data = await _api.getJson(_plansPath, auth: false); // plans often public
      final results = (data['results'] as List? ?? data['data'] as List? ?? data as List?) ?? [];
      return results
          .map((e) => SubscriptionPlan.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      debugPrint('getPlans error: $e');
      rethrow;
    }
  }

  Future<UserSubscription> getCurrent() async {
    final data = await _api.getJson(_currentPath);
    return UserSubscription.fromJson(data);
  }

  Future<UserSubscription> subscribe({
    required int planId,
    required String paymentPeriod, // monthly | yearly
    required String paymentMethod,
  }) async {
    final data = await _api.postJson(_subscribePath, body: {
      'plan_id': planId,
      'payment_period': paymentPeriod,
      'payment_method': paymentMethod,
    });
    return UserSubscription.fromJson(data);
  }
}