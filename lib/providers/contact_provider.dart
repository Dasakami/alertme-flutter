import 'package:flutter/foundation.dart';
import 'package:alertme/models/emergency_contact.dart';
import 'package:alertme/models/user.dart';
import 'package:alertme/services/contact_service.dart';

class ContactProvider with ChangeNotifier {
  final ContactService _contactService = ContactService();
  bool _isLoading = false;

  List<EmergencyContact> get contacts => _contactService.contacts;
  bool get isLoading => _isLoading;

  Future<void> loadContacts(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _contactService.loadContacts(userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addContact(EmergencyContact contact) async {
    await _contactService.addContact(contact);
    notifyListeners();
  }

  Future<void> updateContact(EmergencyContact contact) async {
    await _contactService.updateContact(contact);
    notifyListeners();
  }

  Future<void> deleteContact(String contactId) async {
    await _contactService.deleteContact(contactId);
    notifyListeners();
  }

  bool canAddContact(User user) => _contactService.canAddContact(user.subscriptionTier == SubscriptionTier.premium);
  
  int getContactLimit(User user) => _contactService.getContactLimit(user.subscriptionTier == SubscriptionTier.premium);
}