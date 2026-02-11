enum FeatureType {
  boolean,
  metered,
  creditSystem,
}

class FeatureAccess {
  const FeatureAccess({
    required this.allowed,
    required this.unlimited,
    required this.type,
    this.balance,
  });

  final bool allowed;
  final bool unlimited;
  final int? balance;
  final FeatureType type;

  bool get hasAccess => allowed;
  bool get hasBalance => unlimited || (balance ?? 0) > 0;
}

class FeatureCheckResult {
  const FeatureCheckResult({
    required this.customerId,
    required this.featureId,
    required this.requiredBalance,
    required this.code,
    required this.allowed,
    required this.unlimited,
    required this.type,
    this.balance,
    this.preview,
  });

  final String customerId;
  final String featureId;
  final int requiredBalance;
  final String code;
  final bool allowed;
  final bool unlimited;
  final int? balance;
  final FeatureType type;
  final Object? preview;
}

class FeatureUsageInfo {
  const FeatureUsageInfo({
    required this.current,
    this.limit,
    this.remaining,
  });

  final double current;
  final double? limit;
  final double? remaining;
}

class FeatureUsageResult {
  const FeatureUsageResult({
    required this.success,
    required this.featureId,
    required this.amountUsed,
    this.message,
    this.usage,
  });

  final bool success;
  final String featureId;
  final double amountUsed;
  final String? message;
  final FeatureUsageInfo? usage;
}
