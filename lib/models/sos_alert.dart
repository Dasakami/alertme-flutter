import 'package:alertme/models/sos_notification.dart';

class SOSAlertModel {
  final int id;
  final String status;
  final double? latitude;
  final double? longitude;
  final double? locationAccuracy;
  final String? address;
  final String? mapLink;
  final String? audioFile;
  final String? videoFile;
  final String? activationMethod; 
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

  bool get isActive => status == 'active';

  String get mapUrl {
    if (latitude != null && longitude != null) {
      return 'https://go.2gis.com/show_point?lat=$latitude&lon=$longitude';
    }
    return mapLink ?? '';
  }
  factory SOSAlertModel.fromJson(Map<String, dynamic> json) {
    double? parseCoordinate(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed;
      }
      return null;
    }

    return SOSAlertModel(
      id: json['id'] as int,
      status: json['status'] as String,
      latitude: parseCoordinate(json['latitude']),
      longitude: parseCoordinate(json['longitude']),
      locationAccuracy: parseCoordinate(json['location_accuracy']),
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
  }

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