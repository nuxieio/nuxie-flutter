enum FeatureCheckPolicy { cacheFirst, remote }

enum FeatureType { boolean, metered, creditSystem }

class FeatureAccess {
  const FeatureAccess({
    required this.allowed,
    required this.unlimited,
    required this.type,
    this.balance,
  });

  final bool allowed;
  final bool unlimited;
  final double? balance;
  final FeatureType type;
}

class FeatureUsageInfo {
  const FeatureUsageInfo({required this.current, this.limit, this.remaining});

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
    this.authoritativeAccess,
  });

  final bool success;
  final String featureId;
  final double amountUsed;
  final String? message;
  final FeatureUsageInfo? usage;
  final FeatureAccess? authoritativeAccess;
}
