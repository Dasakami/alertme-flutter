class LocationHistoryEntry {
  final int id;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final String? address;
  final String? activityType;
  final num? batteryLevel;
  final DateTime timestamp;
  final DateTime createdAt;

  LocationHistoryEntry({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    this.address,
    this.activityType,
    this.batteryLevel,
    required this.timestamp,
    required this.createdAt,
  });

  factory LocationHistoryEntry.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic v) => v == null ? null : (v as num).toDouble();
    return LocationHistoryEntry(
      id: (json['id'] as num).toInt(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: _toDouble(json['accuracy']),
      altitude: _toDouble(json['altitude']),
      speed: _toDouble(json['speed']),
      heading: _toDouble(json['heading']),
      address: json['address'] as String?,
      activityType: json['activity_type'] as String?,
      batteryLevel: json['battery_level'] as num?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'heading': heading,
        'address': address,
        'activity_type': activityType,
        'battery_level': batteryLevel,
        'timestamp': timestamp.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
