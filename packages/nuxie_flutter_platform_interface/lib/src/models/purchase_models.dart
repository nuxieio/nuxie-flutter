enum NuxiePurchaseResultType {
  success,
  cancelled,
  pending,
  failed,
}

class NuxiePurchaseRequest {
  const NuxiePurchaseRequest({
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

class NuxiePurchaseResult {
  const NuxiePurchaseResult({
    required this.type,
    this.message,
    this.productId,
    this.purchaseToken,
    this.orderId,
    this.transactionId,
    this.originalTransactionId,
    this.transactionJws,
  });

  final NuxiePurchaseResultType type;
  final String? message;
  final String? productId;
  final String? purchaseToken;
  final String? orderId;
  final String? transactionId;
  final String? originalTransactionId;
  final String? transactionJws;
}

enum NuxieRestoreResultType {
  success,
  noPurchases,
  failed,
}

class NuxieRestoreRequest {
  const NuxieRestoreRequest({
    required this.requestId,
    required this.platform,
    required this.timestampMs,
  });

  final String requestId;
  final String platform;
  final int timestampMs;
}

class NuxieRestoreResult {
  const NuxieRestoreResult({
    required this.type,
    this.restoredCount,
    this.message,
  });

  final NuxieRestoreResultType type;
  final int? restoredCount;
  final String? message;
}
