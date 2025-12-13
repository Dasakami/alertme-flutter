import 'package:alertme/models/emergency_contact.dart';

class SOSNotificationModel {
  final int id;
  final EmergencyContact? contact;
  final String notificationType; // sms / call / push, etc.
  final String status; // queued/sent/delivered/read/failed
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

  factory SOSNotificationModel.fromJson(Map<String, dynamic> json) => SOSNotificationModel(
        id: (json['id'] as num).toInt(),
        contact: json['contact'] != null
            ? EmergencyContact.fromJson(json['contact'] as Map<String, dynamic>)
            : null,
        notificationType: json['notification_type'] as String? ?? 'sms',
        status: json['status'] as String? ?? 'queued',
        content: json['content'] as String?,
        sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at'] as String) : null,
        deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at'] as String) : null,
        readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
        errorMessage: json['error_message'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'contact': contact?.toJson(),
        'notification_type': notificationType,
        'status': status,
        'content': content,
        'sent_at': sentAt?.toIso8601String(),
        'delivered_at': deliveredAt?.toIso8601String(),
        'read_at': readAt?.toIso8601String(),
        'error_message': errorMessage,
      };
}
