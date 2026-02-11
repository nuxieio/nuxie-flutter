enum PurchaseResultKind {
  success,
  cancelled,
  pending,
  failed,
}

enum RestoreResultKind {
  success,
  noPurchases,
  failed,
}

class PurchaseRequestContract {
  const PurchaseRequestContract({
    required this.requestId,
    required this.platform,
    required this.productId,
    required this.timestampMs,
    this.basePlanId,
    this.offerId,
    this.displayName,
    this.displayPrice,
    this.price,
    this.currencyCode,
  });

  final String requestId;
  final String platform;
  final String productId;
  final int timestampMs;
  final String? basePlanId;
  final String? offerId;
  final String? displayName;
  final String? displayPrice;
  final double? price;
  final String? currencyCode;
}

class RestoreRequestContract {
  const RestoreRequestContract({
    required this.requestId,
    required this.platform,
    required this.timestampMs,
  });

  final String requestId;
  final String platform;
  final int timestampMs;
}
