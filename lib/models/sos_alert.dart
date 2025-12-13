import 'sos_notification.dart';

class SOSAlertModel {
  final int id;
  final int? user; // user id (read-only client-side usage)
  final String? userPhone;
  final String status; // per backend STATUS_CHOICES
  final double? latitude;
  final double? longitude;
  final double? locationAccuracy;
  final String? address;
  final String? mapLink;
  final String? audioFile; // URL or path
  final String? videoFile; // URL or path
  final String? activationMethod;
  final String? notes;
  final Map<String, dynamic>? deviceInfo;
  final List<SOSNotificationModel> notifications;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  SOSAlertModel({
    required this.id,
    this.user,
    this.userPhone,
    required this.status,
    this.latitude,
    this.longitude,
    this.locationAccuracy,
    this.address,
    this.mapLink,
    this.audioFile,
    this.videoFile,
    this.activationMethod,
    this.notes,
    this.deviceInfo,
    this.notifications = const [],
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });

  factory SOSAlertModel.fromJson(Map<String, dynamic> json) => SOSAlertModel(
        id: (json['id'] as num).toInt(),
        user: (json['user'] as num?)?.toInt(),
        userPhone: json['user_phone'] as String?,
        status: json['status'] as String,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        locationAccuracy: (json['location_accuracy'] as num?)?.toDouble(),
        address: json['address'] as String?,
        mapLink: json['map_link'] as String?,
        audioFile: json['audio_file'] as String?,
        videoFile: json['video_file'] as String?,
        activationMethod: json['activation_method'] as String?,
        notes: json['notes'] as String?,
        deviceInfo: json['device_info'] as Map<String, dynamic>?,
        notifications: (json['notifications'] as List?)
                ?.map((e) => SOSNotificationModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const <SOSNotificationModel>[],
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user': user,
        'user_phone': userPhone,
        'status': status,
        'latitude': latitude,
        'longitude': longitude,
        'location_accuracy': locationAccuracy,
        'address': address,
        'map_link': mapLink,
        'audio_file': audioFile,
        'video_file': videoFile,
        'activation_method': activationMethod,
        'notes': notes,
        'device_info': deviceInfo,
        'notifications': notifications.map((e) => e.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'resolved_at': resolvedAt?.toIso8601String(),
      };
}
