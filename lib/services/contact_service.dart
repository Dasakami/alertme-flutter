import 'package:flutter/foundation.dart';
import 'package:alertme/models/emergency_contact.dart';
import 'package:alertme/services/api_client.dart';

class ContactService {
  final ApiClient _api = ApiClient();
  List<EmergencyContact> _contacts = [];

  List<EmergencyContact> get contacts => List.unmodifiable(_contacts);

  Future<void> loadContacts() async {
    try {
      final data = await _api.getJson('/emergency-contacts/', auth: true);
      
      List<dynamic> results; // ИСПРАВЛЕНО
      if (data is List) {
        results = data as List<dynamic>;
      } else if (data['results'] is List) {
        results = data['results'] as List<dynamic>;
      } else if (data['data'] is List) {
        results = data['data'] as List<dynamic>;
      } else {
        results = [];
      }
      
      _contacts = results
          .map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
          .toList();
          
      debugPrint('✅ Загружено ${_contacts.length} контактов');
    } catch (e) {
      debugPrint('❌ Ошибка загрузки контактов: $e');
      _contacts = [];
      rethrow;
    }
  }

  Future<EmergencyContact> addContact(EmergencyContact contact) async {
    try {
      final data = await _api.postJson(
        '/emergency-contacts/',
        body: contact.toJson(),
        auth: true,
      );
      
      final newContact = EmergencyContact.fromJson(data);
      _contacts.add(newContact);
      
      debugPrint('✅ Контакт добавлен: ${newContact.name}');
      return newContact;
    } catch (e) {
      debugPrint('❌ Ошибка добавления контакта: $e');
      rethrow;
    }
  }

  Future<EmergencyContact> updateContact(int id, EmergencyContact contact) async {
    try {
      final data = await _api.putJson(
        '/emergency-contacts/$id/',
        body: contact.toJson(),
        auth: true,
      );
      
      final updated = EmergencyContact.fromJson(data);
      final index = _contacts.indexWhere((c) => c.id == id);
      
      if (index != -1) {
        _contacts[index] = updated;
      }
      
      debugPrint('✅ Контакт обновлен: ${updated.name}');
      return updated;
    } catch (e) {
      debugPrint('❌ Ошибка обновления контакта: $e');
      rethrow;
    }
  }

  Future<void> deleteContact(int contactId) async {
    try {
      await _api.delete('/emergency-contacts/$contactId/', auth: true);
      _contacts.removeWhere((c) => c.id == contactId);
      debugPrint('✅ Контакт удален: $contactId');
    } catch (e) {
      debugPrint('❌ Ошибка удаления контакта: $e');
      rethrow;
    }
  }

  Future<void> setPrimary(int contactId) async {
    try {
      await _api.postJson(
        '/emergency-contacts/$contactId/set_primary/',
        auth: true,
      );
      
      for (var i = 0; i < _contacts.length; i++) {
        _contacts[i] = _contacts[i].copyWith(
          isPrimary: _contacts[i].id == contactId,
          updatedAt: DateTime.now(),
        );
      }
      
      debugPrint('✅ Основной контакт установлен: $contactId');
    } catch (e) {
      debugPrint('❌ Ошибка установки основного контакта: $e');
      rethrow;
    }
  }

  bool canAddContact(int maxContacts) => _contacts.length < maxContacts;
  
  void clearCache() => _contacts = [];
}