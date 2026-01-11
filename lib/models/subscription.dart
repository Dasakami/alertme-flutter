class SubscriptionPlan {
  final int id;
  final String name;
  final String planType; 
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

  bool get isFree => planType == 'free' || priceMonthly == 0;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed ?? 0;
      }
      return 0;
    }

    List<String> parseFeatures(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      if (value is Map) {
        return value.keys.map((e) => e.toString()).toList();
      }
      return [];
    }

    return SubscriptionPlan(
      id: json['id'] as int,
      name: json['name'] as String,
      planType: json['plan_type'] as String,
      description: json['description'] as String?,
      priceMonthly: parsePrice(json['price_monthly']),
      priceYearly: parsePrice(json['price_yearly']),
      features: parseFeatures(json['features']),
      maxContacts: json['max_contacts'] as int?,
      geozonesEnabled: json['geozones_enabled'] as bool? ?? false,
      locationHistoryEnabled: json['location_history_enabled'] as bool? ?? false,
    );
  }

  @override
  String toString() => 'SubscriptionPlan(id: $id, name: $name, type: $planType)';
}

class UserSubscription {
  final int id;
  final SubscriptionPlan plan;
  final String status;
  final String paymentPeriod; 
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

  bool get isExpired => DateTime.now().isAfter(endDate);

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


class PaymentTransaction {
  final int id;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String transactionId;
  final String status; 
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

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed ?? 0;
      }
      return 0;
    }

    return PaymentTransaction(
      id: json['id'] as int,
      amount: parseAmount(json['amount']),
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
}