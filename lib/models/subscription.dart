class SubscriptionPlan {
  final int id;
  final String name;
  final String planType; // free, premium, etc
  final String? description;
  final double priceMonthly;
  final double priceYearly;
  final List<String> features;
  final int? maxContacts;
  final bool geozonesEnabled;
  final bool locationHistoryEnabled;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.planType,
    this.description,
    this.priceMonthly = 0,
    this.priceYearly = 0,
    this.features = const [],
    this.maxContacts,
    this.geozonesEnabled = false,
    this.locationHistoryEnabled = false,
  });

  /// Бесплатный ли план
  bool get isFree => planType == 'free' || priceMonthly == 0;

  /// Создание из JSON
  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) => 
    SubscriptionPlan(
      id: json['id'] as int,
      name: json['name'] as String,
      planType: json['plan_type'] as String,
      description: json['description'] as String?,
      priceMonthly: (json['price_monthly'] as num?)?.toDouble() ?? 0,
      priceYearly: (json['price_yearly'] as num?)?.toDouble() ?? 0,
      features: (json['features'] as List?)?.cast<String>() ?? [],
      maxContacts: json['max_contacts'] as int?,
      geozonesEnabled: json['geozones_enabled'] as bool? ?? false,
      locationHistoryEnabled: json['location_history_enabled'] as bool? ?? false,
    );

  @override
  String toString() => 'SubscriptionPlan(id: $id, name: $name, type: $planType)';
}

/// Модель подписки пользователя
class UserSubscription {
  final int id;
  final SubscriptionPlan plan;
  final String status; // active, inactive, canceled, expired
  final String paymentPeriod; // monthly, yearly
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;
  final int daysRemaining;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSubscription({
    required this.id,
    required this.plan,
    required this.status,
    required this.paymentPeriod,
    required this.startDate,
    required this.endDate,
    required this.autoRenew,
    required this.daysRemaining,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Истекла ли подписка
  bool get isExpired => DateTime.now().isAfter(endDate);

  /// Создание из JSON
  factory UserSubscription.fromJson(Map<String, dynamic> json) => 
    UserSubscription(
      id: json['id'] as int,
      plan: SubscriptionPlan.fromJson(json['plan'] as Map<String, dynamic>),
      status: json['status'] as String,
      paymentPeriod: json['payment_period'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      autoRenew: json['auto_renew'] as bool? ?? true,
      daysRemaining: json['days_remaining'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

  @override
  String toString() => 'UserSubscription(plan: ${plan.name}, status: $status)';
}

/// Модель платежа
class PaymentTransaction {
  final int id;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String transactionId;
  final String status; // pending, completed, failed
  final DateTime createdAt;
  final DateTime? completedAt;

  PaymentTransaction({
    required this.id,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.transactionId,
    required this.status,
    required this.createdAt,
    this.completedAt,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) => 
    PaymentTransaction(
      id: json['id'] as int,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'KGS',
      paymentMethod: json['payment_method'] as String? ?? 'card',
      transactionId: json['transaction_id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String) 
          : null,
    );
}