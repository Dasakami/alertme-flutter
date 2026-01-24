class EmergencyContact {
  final int id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String? relation;
  final bool isPrimary;
  final bool isActive;
  final Map<String, dynamic> notificationPreferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.relation,
    this.isPrimary = false,
    this.isActive = true,
    this.notificationPreferences = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) => 
    EmergencyContact(
      id: json['id'] as int,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      email: json['email'] as String?,
      relation: json['relation'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      notificationPreferences: (json['notification_preferences'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone_number': phoneNumber,
    'email': email,
    'relation': relation,
    'is_primary': isPrimary,
    'notification_preferences': notificationPreferences,
  };

  EmergencyContact copyWith({
    int? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? relation,
    bool? isPrimary,
    bool? isActive,
    Map<String, dynamic>? notificationPreferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => EmergencyContact(
    id: id ?? this.id,
    name: name ?? this.name,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    email: email ?? this.email,
    relation: relation ?? this.relation,
    isPrimary: isPrimary ?? this.isPrimary,
    isActive: isActive ?? this.isActive,
    notificationPreferences: notificationPreferences ?? this.notificationPreferences,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  String toString() => 'EmergencyContact(id: $id, name: $name, phone: $phoneNumber)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmergencyContact &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}