/// Модель пользователя приложения
class UserModel {
  final int id;
  final String phoneNumber;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? telegramUsername; // НОВОЕ ПОЛЕ
  final String? avatar;
  final String language;
  final bool isPhoneVerified;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.phoneNumber,
    this.email,
    this.firstName,
    this.lastName,
    this.telegramUsername, // НОВОЕ
    this.avatar,
    this.language = 'ru',
    this.isPhoneVerified = false,
    required this.createdAt,
  });

  /// Полное имя пользователя
  String get name {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) {
      return firstName!;
    }
    return phoneNumber;
  }

  /// Создание из JSON (от сервера)
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as int,
    phoneNumber: json['phone_number'] as String,
    email: json['email'] as String?,
    firstName: json['first_name'] as String?,
    lastName: json['last_name'] as String?,
    telegramUsername: json['telegram_username'] as String?, // НОВОЕ
    avatar: json['avatar'] as String?,
    language: json['language'] as String? ?? 'ru',
    isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  /// Конвертация в JSON (для отправки на сервер)
  Map<String, dynamic> toJson() => {
    'id': id,
    'phone_number': phoneNumber,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'telegram_username': telegramUsername, // НОВОЕ
    'avatar': avatar,
    'language': language,
    'is_phone_verified': isPhoneVerified,
    'created_at': createdAt.toIso8601String(),
  };

  /// Создание копии с измененными полями
  UserModel copyWith({
    int? id,
    String? phoneNumber,
    String? email,
    String? firstName,
    String? lastName,
    String? telegramUsername, // НОВОЕ
    String? avatar,
    String? language,
    bool? isPhoneVerified,
    DateTime? createdAt,
  }) => UserModel(
    id: id ?? this.id,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    email: email ?? this.email,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    telegramUsername: telegramUsername ?? this.telegramUsername, // НОВОЕ
    avatar: avatar ?? this.avatar,
    language: language ?? this.language,
    isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  String toString() => 'User(id: $id, phone: $phoneNumber, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}