import 'package:alertme/models/sos_notification.dart';

/// Модель SOS сигнала
class SOSAlertModel {
  final int id;
  final String status; // active, responding, resolved, cancelled, false_alarm
  final double? latitude;
  final double? longitude;
  final double? locationAccuracy;
  final String? address;
  final String? mapLink;
  final String? audioFile;
  final String? videoFile;
  final String? activationMethod; // button, volume_keys, shake, timer
  final String? notes;
  final List<SOSNotificationModel> notifications;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  SOSAlertModel({
    required this.id,
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
    this.notifications = const [],
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });

  /// Активен ли сигнал
  bool get isActive => status == 'active';

  /// Ссылка на 2GIS карту
  String get mapUrl {
    if (latitude != null && longitude != null) {
      return 'https://go.2gis.com/show_point?lat=$latitude&lon=$longitude';
    }
    return mapLink ?? '';
  }

  /// Создание из JSON
  factory SOSAlertModel.fromJson(Map<String, dynamic> json) => SOSAlertModel(
    id: json['id'] as int,
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
    notifications: (json['notifications'] as List?)
        ?.map((e) => SOSNotificationModel.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    resolvedAt: json['resolved_at'] != null 
        ? DateTime.parse(json['resolved_at'] as String) 
        : null,
  );

  /// Конвертация в JSON
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'location_accuracy': locationAccuracy,
    'address': address,
    'activation_method': activationMethod,
    'notes': notes,
  };

  @override
  String toString() => 'SOSAlert(id: $id, status: $status, time: $createdAt)';
}
