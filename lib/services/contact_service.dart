import 'package:flutter/foundation.dart';
import 'package:alertme/models/emergency_contact.dart';
import 'package:alertme/services/storage_service.dart';

class ContactService {
  final StorageService _storage = StorageService();
  List<EmergencyContact> _contacts = [];

  List<EmergencyContact> get contacts => List.unmodifiable(_contacts);

  Future<void> loadContacts(String userId) async {
    try {
      final jsonList = await _storage.getJsonList(_storage.contactsKey);
      final List<EmergencyContact> loadedContacts = [];
      
      for (final json in jsonList) {
        try {
          final contact = EmergencyContact.fromJson(json);
          if (contact.userId == userId) {
            loadedContacts.add(contact);
          }
        } catch (e) {
          debugPrint('Skipping corrupted contact: $e');
        }
      }
      
      _contacts = loadedContacts;
      await _saveContacts();
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      _contacts = [];
    }
  }

  Future<void> addContact(EmergencyContact contact) async {
    try {
      _contacts.add(contact);
      await _saveContacts();
    } catch (e) {
      debugPrint('Error adding contact: $e');
    }
  }

  Future<void> updateContact(EmergencyContact contact) async {
    try {
      final index = _contacts.indexWhere((c) => c.id == contact.id);
      if (index != -1) {
        _contacts[index] = contact;
        await _saveContacts();
      }
    } catch (e) {
      debugPrint('Error updating contact: $e');
    }
  }

  Future<void> deleteContact(String contactId) async {
    try {
      _contacts.removeWhere((c) => c.id == contactId);
      await _saveContacts();
    } catch (e) {
      debugPrint('Error deleting contact: $e');
    }
  }

  Future<void> _saveContacts() async {
    try {
      final jsonList = _contacts.map((c) => c.toJson()).toList();
      await _storage.saveJsonList(_storage.contactsKey, jsonList);
    } catch (e) {
      debugPrint('Error saving contacts: $e');
    }
  }

  int getContactLimit(bool isPremium) => isPremium ? 999 : 1;

  bool canAddContact(bool isPremium) {
    final limit = getContactLimit(isPremium);
    return _contacts.length < limit;
  }
}
