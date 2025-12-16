class SOSEvent {
  final String id;
  final String userId;
  final DateTime timestamp;
  final LocationData? location;
  final SOSStatus status;
  final String? audioUrl;
  final String? videoUrl;
  final List<String> notifiedContacts;

  SOSEvent({
    required this.id,
    required this.userId,
    required this.timestamp,
    this.location,
    this.status = SOSStatus.active,
    this.audioUrl,
    this.videoUrl,
    this.notifiedContacts = const [],
  });

  factory SOSEvent.fromJson(Map<String, dynamic> json) => SOSEvent(
    id: json['id'] as String,
    userId: json['userId'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    location: json['location'] != null ? LocationData.fromJson(json['location']) : null,
    status: SOSStatus.values.firstWhere(
      (e) => e.toString() == 'SOSStatus.${json['status']}',
      orElse: () => SOSStatus.active,
    ),
    audioUrl: json['audioUrl'] as String?,
    videoUrl: json['videoUrl'] as String?,
    notifiedContacts: (json['notifiedContacts'] as List?)?.cast<String>() ?? [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'timestamp': timestamp.toIso8601String(),
    'location': location?.toJson(),
    'status': status.name,
    'audioUrl': audioUrl,
    'videoUrl': videoUrl,
    'notifiedContacts': notifiedContacts,
  };

  SOSEvent copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    LocationData? location,
    SOSStatus? status,
    String? audioUrl,
    String? videoUrl,
    List<String>? notifiedContacts,
  }) => SOSEvent(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    timestamp: timestamp ?? this.timestamp,
    location: location ?? this.location,
    status: status ?? this.status,
    audioUrl: audioUrl ?? this.audioUrl,
    videoUrl: videoUrl ?? this.videoUrl,
    notifiedContacts: notifiedContacts ?? this.notifiedContacts,
  );
}
class LocationData {
  final double latitude;
  final double longitude;
  final String? address;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) => LocationData(
    latitude: json['latitude'] as double,
    longitude: json['longitude'] as double,
    address: json['address'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
  };

  // ИЗМЕНЕНО: Используем Google Maps вместо 2GIS
  String get mapUrl => 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
}
enum SOSStatus { active, cancelled, completed }
