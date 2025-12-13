import 'package:flutter/foundation.dart';
import 'package:alertme/models/user.dart';
import 'package:alertme/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _authService.currentUser;
  bool get isAuthenticated => _authService.isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    await _authService.init();
    notifyListeners();
  }

  Future<bool> register({
    required String phoneNumber,
    required String password,
    required String passwordConfirm,
    String? email,
    String language = 'ru',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.register(
        phoneNumber: phoneNumber,
        password: password,
        passwordConfirm: passwordConfirm,
        email: email,
        language: language,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String phoneNumber, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ok = await _authService.login(phoneNumber: phoneNumber, password: password);
      if (ok) notifyListeners();
      return ok;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendOTP(String phoneNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      return await _authService.sendOTP(phoneNumber);
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOTP(String phoneNumber, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ok = await _authService.verifyOTP(phoneNumber, otp);
      if (!ok) _error = 'Неверный код';
      if (ok) notifyListeners();
      return ok;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(User user) async {
    await _authService.updateUser(user);
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }
}
