class EmergencyContact {
  final String id;
  final String userId;
  final String name;
  final String phoneNumber;
  final String? email;
  final bool isPrimary;
  final DateTime createdAt;

  EmergencyContact({
    required this.id,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.isPrimary = false,
    required this.createdAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) => EmergencyContact(
    id: json['id'] as String,
    userId: json['userId'] as String,
    name: json['name'] as String,
    phoneNumber: json['phoneNumber'] as String,
    email: json['email'] as String?,
    isPrimary: json['isPrimary'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'phoneNumber': phoneNumber,
    'email': email,
    'isPrimary': isPrimary,
    'createdAt': createdAt.toIso8601String(),
  };

  EmergencyContact copyWith({
    String? id,
    String? userId,
    String? name,
    String? phoneNumber,
    String? email,
    bool? isPrimary,
    DateTime? createdAt,
  }) => EmergencyContact(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    email: email ?? this.email,
    isPrimary: isPrimary ?? this.isPrimary,
    createdAt: createdAt ?? this.createdAt,
  );
}
