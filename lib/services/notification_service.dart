import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:alertme/models/emergency_contact.dart';

class NotificationService {
  /// Отправка SMS
  Future<bool> sendSMS(EmergencyContact contact, String message) async {
    try {
      // SMS URL схема: sms:номер?body=текст
      final smsUrl = Uri.parse(
        'sms:${contact.phoneNumber}?body=${Uri.encodeComponent(message)}'
      );
      
      if (await canLaunchUrl(smsUrl)) {
        final launched = await launchUrl(
          smsUrl,
          mode: LaunchMode.externalApplication,
        );
        
        if (launched) {
          debugPrint('✅ SMS отправлено на ${contact.phoneNumber}');
          return true;
        }
      }
      
      debugPrint('❌ Не удалось отправить SMS');
      return false;
    } catch (e) {
      debugPrint('❌ Ошибка отправки SMS: $e');
      return false;
    }
  }

  /// Совершение звонка
  Future<bool> makeCall(EmergencyContact contact) async {
    try {
      // Tel URL схема: tel:номер
      final telUrl = Uri.parse('tel:${contact.phoneNumber}');
      
      if (await canLaunchUrl(telUrl)) {
        final launched = await launchUrl(
          telUrl,
          mode: LaunchMode.externalApplication,
        );
        
        if (launched) {
          debugPrint('✅ Звонок на ${contact.phoneNumber}');
          return true;
        }
      }
      
      debugPrint('❌ Не удалось позвонить');
      return false;
    } catch (e) {
      debugPrint('❌ Ошибка звонка: $e');
      return false;
    }
  }

  /// Отправка SMS всем контактам
  Future<Map<String, bool>> sendSOSToAll(
    List<EmergencyContact> contacts,
    String message,
  ) async {
    final results = <String, bool>{};
    
    for (final contact in contacts) {
      results[contact.phoneNumber] = await sendSMS(contact, message);
      
      // Небольшая задержка между отправками
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    return results;
  }

  /// Позвонить основному контакту
  Future<bool> callPrimaryContact(List<EmergencyContact> contacts) async {
    final primary = contacts.where((c) => c.isPrimary).firstOrNull;
    
    if (primary != null) {
      return await makeCall(primary);
    }
    
    // Если нет основного, звоним первому
    if (contacts.isNotEmpty) {
      return await makeCall(contacts.first);
    }
    
    return false;
  }

  /// Генерация SOS сообщения
  String generateSOSMessage({
    required String userName,
    required double? latitude,
    required double? longitude,
    String? address,
  }) {
    String message = '🚨 ЭКСТРЕННАЯ ТРЕВОГА!\n\n';
    message += '$userName активировал SOS!\n\n';
    
    if (latitude != null && longitude != null) {
      final googleMapsUrl = 
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      message += '📍 Местоположение:\n$googleMapsUrl\n\n';
      
      if (address != null && address.isNotEmpty) {
        message += 'Адрес: $address\n\n';
      }
    }
    
    message += '⏰ Время: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
    message += '\n\n❗ Это автоматическое сообщение из приложения AlertMe';
    
    return message;
  }
}