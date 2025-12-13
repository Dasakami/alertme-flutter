class SafetyTimer {
  final String id;
  final String userId;
  final Duration duration;
  final DateTime startTime;
  final DateTime expiryTime;
  final bool isActive;

  SafetyTimer({
    required this.id,
    required this.userId,
    required this.duration,
    required this.startTime,
    required this.expiryTime,
    this.isActive = true,
  });

  factory SafetyTimer.fromJson(Map<String, dynamic> json) => SafetyTimer(
    id: json['id'] as String,
    userId: json['userId'] as String,
    duration: Duration(seconds: json['durationSeconds'] as int),
    startTime: DateTime.parse(json['startTime'] as String),
    expiryTime: DateTime.parse(json['expiryTime'] as String),
    isActive: json['isActive'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'durationSeconds': duration.inSeconds,
    'startTime': startTime.toIso8601String(),
    'expiryTime': expiryTime.toIso8601String(),
    'isActive': isActive,
  };

  SafetyTimer copyWith({
    String? id,
    String? userId,
    Duration? duration,
    DateTime? startTime,
    DateTime? expiryTime,
    bool? isActive,
  }) => SafetyTimer(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    duration: duration ?? this.duration,
    startTime: startTime ?? this.startTime,
    expiryTime: expiryTime ?? this.expiryTime,
    isActive: isActive ?? this.isActive,
  );

  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(expiryTime)) return Duration.zero;
    return expiryTime.difference(now);
  }

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}
