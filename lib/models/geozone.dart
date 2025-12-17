import 'package:alertme/models/emergency_contact.dart';

class Geozone {
  final int id;
  final String name;
  final String? description;
  final String zoneType; 
  final double latitude;
  final double longitude;
  final double radius; 
  final List<List<double>>? polygonCoordinates; 
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
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.polygonCoordinates,
    this.notifyOnEnter = true,
    this.notifyOnExit = true,
    this.isActive = true,
    this.emergencyContacts = const [],
    required this.createdAt,
    required this.updatedAt,
  });
  factory Geozone.fromJson(Map<String, dynamic> json) {
    List<List<double>>? parsePolygon(dynamic v) {
      if (v is List) {
        return v.map((p) {
          if (p is List && p.length >= 2) {
            return [
              (p[0] as num).toDouble(),
              (p[1] as num).toDouble(),
            ];
          }
          return <double>[];
        }).where((e) => e.isNotEmpty).toList();
      }
      return null;
    }

    return Geozone(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      zoneType: json['zone_type'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num).toDouble(),
      polygonCoordinates: parsePolygon(json['polygon_coordinates']),
      notifyOnEnter: json['notify_on_enter'] as bool? ?? true,
      notifyOnExit: json['notify_on_exit'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
      emergencyContacts: (json['emergency_contacts'] as List?)
          ?.map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Конвертация в JSON
  Map<String, dynamic> toJson() => {
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
    'contact_ids': emergencyContacts.map((e) => e.id).toList(),
  };

  @override
  String toString() => 'Geozone(id: $id, name: $name, type: $zoneType)';
}

/// Модель события геозоны
class GeozoneEvent {
  final int id;
  final int geozoneId;
  final String? geozoneName;
  final String eventType; // enter, exit
  final double latitude;
  final double longitude;
  final bool notificationSent;
  final DateTime timestamp;

  GeozoneEvent({
    required this.id,
    required this.geozoneId,
    this.geozoneName,
    required this.eventType,
    required this.latitude,
    required this.longitude,
    required this.notificationSent,
    required this.timestamp,
  });

  factory GeozoneEvent.fromJson(Map<String, dynamic> json) => GeozoneEvent(
    id: json['id'] as int,
    geozoneId: json['geozone'] as int,
    geozoneName: json['geozone_name'] as String?,
    eventType: json['event_type'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    notificationSent: json['notification_sent'] as bool? ?? false,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  @override
  String toString() => 'GeozoneEvent(type: $eventType, zone: $geozoneName)';
}
