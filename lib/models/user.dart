class User {
  final String id;
  final String phoneNumber;
  final String? email;
  final String name;
  final String preferredLanguage;
  final SubscriptionTier subscriptionTier;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.phoneNumber,
    this.email,
    required this.name,
    this.preferredLanguage = 'ru',
    this.subscriptionTier = SubscriptionTier.free,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    phoneNumber: json['phoneNumber'] as String,
    email: json['email'] as String?,
    name: json['name'] as String,
    preferredLanguage: json['preferredLanguage'] as String? ?? 'ru',
    subscriptionTier: SubscriptionTier.values.firstWhere(
      (e) => e.toString() == 'SubscriptionTier.${json['subscriptionTier']}',
      orElse: () => SubscriptionTier.free,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'phoneNumber': phoneNumber,
    'email': email,
    'name': name,
    'preferredLanguage': preferredLanguage,
    'subscriptionTier': subscriptionTier.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  User copyWith({
    String? id,
    String? phoneNumber,
    String? email,
    String? name,
    String? preferredLanguage,
    SubscriptionTier? subscriptionTier,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => User(
    id: id ?? this.id,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    email: email ?? this.email,
    name: name ?? this.name,
    preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    subscriptionTier: subscriptionTier ?? this.subscriptionTier,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

enum SubscriptionTier { free, premium }
