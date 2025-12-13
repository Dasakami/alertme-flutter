import 'package:alertme/models/emergency_contact.dart';

class Geozone {
  final int id;
  final String name;
  final String? description;
  final String zoneType; // e.g. 'circle' | 'polygon'
  final double? latitude;
  final double? longitude;
  final double? radius;
  final List<List<double>>? polygonCoordinates; // [[lat, lon], ...]
  final bool notifyOnEnter;
  final bool notifyOnExit;
  final bool isActive;
  final List<EmergencyContact> emergencyContacts;
  final DateTime createdAt;
  final DateTime updatedAt;

  Geozone({
    required this.id,
    required this.name,
    this.description,
    required this.zoneType,
    this.latitude,
    this.longitude,
    this.radius,
    this.polygonCoordinates,
    this.notifyOnEnter = false,
    this.notifyOnExit = false,
    this.isActive = true,
    this.emergencyContacts = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Geozone.fromJson(Map<String, dynamic> json) {
    List<List<double>>? parsePolygon(dynamic v) {
      if (v is List) {
        return v
            .map((p) => (p as List)
                .take(2)
                .map((n) => (n as num).toDouble())
                .toList())
            .map((e) => [e[0], e[1]])
            .toList();
      }
      return null;
    }

    final contacts = (json['emergency_contacts'] as List?)
            ?.map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <EmergencyContact>[];

    return Geozone(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      zoneType: json['zone_type'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      radius: (json['radius'] as num?)?.toDouble(),
      polygonCoordinates: parsePolygon(json['polygon_coordinates']),
      notifyOnEnter: json['notify_on_enter'] as bool? ?? false,
      notifyOnExit: json['notify_on_exit'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      emergencyContacts: contacts,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'zone_type': zoneType,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'polygon_coordinates': polygonCoordinates,
        'notify_on_enter': notifyOnEnter,
        'notify_on_exit': notifyOnExit,
        'is_active': isActive,
        'emergency_contacts': emergencyContacts.map((e) => e.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class GeozoneEvent {
  final int id;
  final int geozone; // geozone id
  final String? geozoneName; // read-only
  final String eventType; // enter | exit
  final double latitude;
  final double longitude;
  final bool notificationSent;
  final DateTime timestamp;

  GeozoneEvent({
    required this.id,
    required this.geozone,
    this.geozoneName,
    required this.eventType,
    required this.latitude,
    required this.longitude,
    required this.notificationSent,
    required this.timestamp,
  });

  factory GeozoneEvent.fromJson(Map<String, dynamic> json) => GeozoneEvent(
        id: (json['id'] as num).toInt(),
        geozone: (json['geozone'] as num).toInt(),
        geozoneName: json['geozone_name'] as String?,
        eventType: json['event_type'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        notificationSent: json['notification_sent'] as bool? ?? false,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'geozone': geozone,
        'geozone_name': geozoneName,
        'event_type': eventType,
        'latitude': latitude,
        'longitude': longitude,
        'notification_sent': notificationSent,
        'timestamp': timestamp.toIso8601String(),
      };
}
