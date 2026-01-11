import 'package:alertme/models/emergency_contact.dart';

class SharedLocationModel {
  final int id;
  final EmergencyContact? sharedWith;
  final int? sharedWithId; 
  final String shareToken;
  final String? shareUrl;
  final int durationMinutes;
  final DateTime? startTime;
  final DateTime? endTime;
  final String status; 
  final int timeRemaining; 
  final DateTime createdAt;

  SharedLocationModel({
    required this.id,
    this.sharedWith,
    this.sharedWithId,
    required this.shareToken,
    this.shareUrl,
    required this.durationMinutes,
    this.startTime,
    this.endTime,
    required this.status,
    required this.timeRemaining,
    required this.createdAt,
  });

  factory SharedLocationModel.fromJson(Map<String, dynamic> json) => SharedLocationModel(
        id: (json['id'] as num).toInt(),
        sharedWith: json['shared_with'] != null
            ? EmergencyContact.fromJson(json['shared_with'] as Map<String, dynamic>)
            : null,
        shareToken: json['share_token'] as String? ?? '',
        shareUrl: json['share_url'] as String?,
        durationMinutes: (json['duration_minutes'] as num).toInt(),
        startTime: json['start_time'] != null ? DateTime.parse(json['start_time'] as String) : null,
        endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
        status: json['status'] as String? ?? 'active',
        timeRemaining: (json['time_remaining'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'shared_with': sharedWith?.toJson(),
        'shared_with_id': sharedWithId,
        'share_token': shareToken,
        'share_url': shareUrl,
        'duration_minutes': durationMinutes,
        'start_time': startTime?.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'status': status,
        'time_remaining': timeRemaining,
        'created_at': createdAt.toIso8601String(),
      };
}