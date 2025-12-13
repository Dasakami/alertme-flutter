class ActivityTimerModel {
  final int id;
  final int durationMinutes;
  final DateTime? startTime;
  final DateTime? endTime;
  final String status; // active | paused | completed | canceled
  final String? checkInMessage;
  final int timeRemaining; // seconds
  final DateTime createdAt;

  ActivityTimerModel({
    required this.id,
    required this.durationMinutes,
    this.startTime,
    this.endTime,
    required this.status,
    this.checkInMessage,
    required this.timeRemaining,
    required this.createdAt,
  });

  factory ActivityTimerModel.fromJson(Map<String, dynamic> json) => ActivityTimerModel(
        id: (json['id'] as num).toInt(),
        durationMinutes: (json['duration_minutes'] as num).toInt(),
        startTime: json['start_time'] != null ? DateTime.parse(json['start_time'] as String) : null,
        endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
        status: json['status'] as String? ?? 'active',
        checkInMessage: json['check_in_message'] as String?,
        timeRemaining: (json['time_remaining'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'duration_minutes': durationMinutes,
        'start_time': startTime?.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'status': status,
        'check_in_message': checkInMessage,
        'time_remaining': timeRemaining,
        'created_at': createdAt.toIso8601String(),
      };
}
