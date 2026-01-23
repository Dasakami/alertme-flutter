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
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Ошибка загрузки планов: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCurrentSubscription() async {
    try {
      await _service.loadCurrentSubscription();
      _error = null;
      debugPrint('✅ Подписка обновлена: isPremium = $isPremium');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Ошибка загрузки подписки: $e');
      notifyListeners();
    }
  }

  Future<bool> activateCode(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _service.activateCode(code);
      
      if (success) {
        // Обновляем текущую подписку после успешной активации
        await loadCurrentSubscription();
        debugPrint('✅ Код активирован, подписка обновлена');
      }
      
      _isLoading = false;
      _error = null;
      notifyListeners();
      return success;
      
    } catch (e) {
      // Сохраняем ошибку для отображения
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      
      // Пробрасываем ошибку выше для обработки в UI
      rethrow;
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
      
      await loadCurrentSubscription();
      
      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> cancelSubscription() async {
    try {
      await _service.cancelSubscription();
      await loadCurrentSubscription();
      
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Метод для очистки ошибок
  void clearError() {
    _error = null;
    notifyListeners();
  }
}