import 'package:flutter/foundation.dart';
import 'package:alertme/models/user.dart';
import 'package:alertme/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _authService.currentUser;
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

  Future<bool> login({required String phoneNumber, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ok = await _authService.login(phoneNumber: phoneNumber, password: password);
      _isLoading = false;
      notifyListeners();
      return ok;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendOTP(String phoneNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendOTP(phoneNumber);
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

  Future<bool> verifyOTP(String phoneNumber, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ok = await _authService.verifyOTP(phoneNumber, otp);
      _isLoading = false;
      notifyListeners();
      return ok;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile({
  String? email,
  String? firstName,
  String? lastName,
  String? telegramUsername, // ДОБАВИТЬ
  String? language,
}) async {
  try {
    await _authService.updateProfile(
      email: email,
      firstName: firstName,
      lastName: lastName,
      telegramUsername: telegramUsername, // ДОБАВИТЬ
      language: language,
    );
    notifyListeners();
  } catch (e) {
    _error = e.toString();
    notifyListeners();
  }
}

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }
}