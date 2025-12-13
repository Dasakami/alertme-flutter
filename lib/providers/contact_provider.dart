import 'package:flutter/foundation.dart';
import 'package:alertme/models/emergency_contact.dart';
import 'package:alertme/services/contact_service.dart';

class ContactProvider with ChangeNotifier {
  final ContactService _service = ContactService();
  bool _isLoading = false;
  String? _error;

  List<EmergencyContact> get contacts => _service.contacts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadContacts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.loadContacts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addContact(EmergencyContact contact) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.addContact(contact);
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

  Future<bool> updateContact(int id, EmergencyContact contact) async {
    try {
      await _service.updateContact(id, contact);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteContact(int contactId) async {
    try {
      await _service.deleteContact(contactId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> setPrimary(int contactId) async {
    try {
      await _service.setPrimary(contactId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  bool canAddContact(int maxContacts) => _service.canAddContact(maxContacts);
}