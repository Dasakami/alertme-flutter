import 'package:flutter/foundation.dart';
import 'package:alertme/models/subscription.dart';
import 'package:alertme/services/subscription_service.dart';

class SubscriptionProvider with ChangeNotifier {
  final SubscriptionService _service = SubscriptionService();
  bool _isLoading = false;
  String? _error;

  List<SubscriptionPlan> get plans => _service.plans;
  UserSubscription? get currentSubscription => _service.currentSubscription;
  bool get hasActiveSubscription => _service.hasActiveSubscription;
  bool get isPremium => _service.isPremium;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPlans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.loadPlans();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCurrentSubscription() async {
    try {
      await _service.loadCurrentSubscription();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> subscribe({
    required int planId,
    required String paymentPeriod,
    required String paymentMethod,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.subscribe(
        planId: planId,
        paymentPeriod: paymentPeriod,
        paymentMethod: paymentMethod,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelSubscription() async {
    try {
      await _service.cancelSubscription();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}