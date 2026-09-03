enum NuxiePurchaseResultType { purchased, cancelled, pending, failed }

class NuxiePurchaseRequest {
  const NuxiePurchaseRequest({
    required this.requestId,
    required this.platform,
    required this.productId,
    required this.storeProductId,
    required this.timestampMs,
    this.basePlanId,
    this.purchaseOptionId,
    this.offerId,
    this.placementId,
    this.displayName,
    this.displayPrice,
  });

  final String requestId;
  final String platform;
  final String productId;
  final String storeProductId;
  final String? basePlanId;
  final String? purchaseOptionId;
  final String? offerId;
  final String? placementId;
  final String? displayName;
  final String? displayPrice;
  final int timestampMs;
}

class NuxiePurchaseResult {
  const NuxiePurchaseResult({required this.type, this.message});

  final NuxiePurchaseResultType type;
  final String? message;
}

enum NuxieRestoreResultType { restored, noPurchases, failed }

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
  const NuxieRestoreResult({required this.type, this.message});

  final NuxieRestoreResultType type;
  final String? message;
}

abstract interface class NuxiePurchaseController {
  Future<NuxiePurchaseResult> purchase(NuxiePurchaseRequest request);

  Future<NuxieRestoreResult> restore(NuxieRestoreRequest request);
}
