import 'package:alertme/models/emergency_contact.dart';

/// Модель уведомления о SOS сигнале
class SOSNotificationModel {
  final int id;
  final EmergencyContact? contact;
  final String notificationType; // sms, call, push
  final String status; // queued, sent, delivered, read, failed
  final String? content;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? errorMessage;

  SOSNotificationModel({
    required this.id,
    this.contact,
    required this.notificationType,
    required this.status,
    this.content,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.errorMessage,
  });

  /// Успешно ли отправлено
  bool get isSent => status == 'sent' || status == 'delivered' || status == 'read';

  /// Доставлено ли
  bool get isDelivered => status == 'delivered' || status == 'read';

  /// Создание из JSON
  factory SOSNotificationModel.fromJson(Map<String, dynamic> json) => 
    SOSNotificationModel(
      id: json['id'] as int,
      contact: json['contact'] != null
          ? EmergencyContact.fromJson(json['contact'] as Map<String, dynamic>)
          : null,
      notificationType: json['notification_type'] as String? ?? 'sms',
      status: json['status'] as String? ?? 'queued',
      content: json['content'] as String?,
      sentAt: json['sent_at'] != null 
          ? DateTime.parse(json['sent_at'] as String) 
          : null,
      deliveredAt: json['delivered_at'] != null 
          ? DateTime.parse(json['delivered_at'] as String) 
          : null,
      readAt: json['read_at'] != null 
          ? DateTime.parse(json['read_at'] as String) 
          : null,
      errorMessage: json['error_message'] as String?,
    );

  @override
  String toString() => 'SOSNotification(id: $id, type: $notificationType, status: $status)';
}