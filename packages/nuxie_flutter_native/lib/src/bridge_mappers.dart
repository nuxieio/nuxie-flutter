import 'package:nuxie_flutter_platform_interface/nuxie_flutter_platform_interface.dart';

import 'generated/nuxie_bridge.g.dart';

PConfigureRequest toConfigureRequest({
  required String apiKey,
  required String wrapperVersion,
  required bool usingPurchaseController,
  required NuxieOptions options,
}) {
  return PConfigureRequest(
    apiKey: apiKey,
    wrapperVersion: wrapperVersion,
    usingPurchaseController: usingPurchaseController,
    environment: options.environment.name,
    logLevel: options.logLevel?.name,
    enableConsoleLogging: options.enableConsoleLogging,
    redactSensitiveData: options.redactSensitiveData,
    localeIdentifier: options.localeIdentifier,
    purchaseHandlingMode: options.purchaseHandlingMode?.name,
    testStoreEnabled: options.testStoreEnabled,
  );
}

FeatureAccess fromFeatureAccess(PFeatureAccess value) {
  return FeatureAccess(
    allowed: value.allowed ?? false,
    unlimited: value.unlimited ?? false,
    balance: value.balance,
    type: FeatureType.values.byName(value.type ?? FeatureType.boolean.name),
  );
}

FeatureUsageResult fromFeatureUsageResult(PFeatureUsageResult value) {
  final usage = value.usageCurrent == null
      ? null
      : FeatureUsageInfo(
          current: value.usageCurrent!,
          limit: value.usageLimit,
          remaining: value.usageRemaining,
        );
  return FeatureUsageResult(
    success: value.success ?? false,
    featureId: value.featureId ?? '',
    amountUsed: value.amountUsed ?? 0,
    message: value.message,
    usage: usage,
    authoritativeAccess: value.authoritativeAccess == null
        ? null
        : fromFeatureAccess(value.authoritativeAccess!),
  );
}

FeatureAccessChangedEvent fromFeatureAccessChangedEvent(
  PFeatureAccessChangedEvent value,
) {
  final next = value.to;
  if (next == null) {
    throw StateError('feature access change omitted its new value');
  }
  return FeatureAccessChangedEvent(
    featureId: value.featureId ?? '',
    from: value.from == null ? null : fromFeatureAccess(value.from!),
    to: fromFeatureAccess(next),
    timestampMs: value.timestampMs ?? 0,
  );
}

NuxieActivityInfo fromActivityInfo(PActivityInfo value) {
  return NuxieActivityInfo(
    schemaVersion: value.schemaVersion ?? 1,
    id: value.id ?? '',
    timestampMs: value.timestampMs ?? 0,
    receivedAtMs: value.receivedAtMs ?? 0,
    name: value.name ?? '',
    properties: _scalarMap(value.properties),
  );
}

AppAction fromAppAction(PAppAction value) {
  final experience = value.experience;
  if (experience == null) {
    throw StateError('App Action omitted its Experience reference');
  }
  return AppAction(
    name: value.name ?? '',
    payload: value.payload == null ? null : _scalarMap(value.payload),
    experience: ExperienceRef(
      experienceId: experience.experienceId ?? '',
      experienceVersion: experience.experienceVersion,
      journeyId: experience.journeyId,
    ),
  );
}

NuxiePurchaseRequest fromPurchaseRequest(PPurchaseRequest value) {
  return NuxiePurchaseRequest(
    requestId: value.requestId ?? '',
    platform: value.platform ?? '',
    productId: value.productId ?? '',
    storeProductId: value.storeProductId ?? '',
    basePlanId: value.basePlanId,
    purchaseOptionId: value.purchaseOptionId,
    offerId: value.offerId,
    placementId: value.placementId,
    displayName: value.displayName,
    displayPrice: value.displayPrice,
    timestampMs: value.timestampMs ?? 0,
  );
}

NuxieRestoreRequest fromRestoreRequest(PRestoreRequest value) {
  return NuxieRestoreRequest(
    requestId: value.requestId ?? '',
    platform: value.platform ?? '',
    timestampMs: value.timestampMs ?? 0,
  );
}

PPurchaseResult toPurchaseResult(NuxiePurchaseResult value) {
  return PPurchaseResult(
    type: value.type.name,
    message: value.message,
  );
}

PRestoreResult toRestoreResult(NuxieRestoreResult value) {
  return PRestoreResult(
    type: switch (value.type) {
      NuxieRestoreResultType.restored => 'restored',
      NuxieRestoreResultType.noPurchases => 'no_purchases',
      NuxieRestoreResultType.failed => 'failed',
    },
    message: value.message,
  );
}

Map<String, Object> _scalarMap(Map<String?, Object?>? values) {
  final result = <String, Object>{};
  for (final entry in values?.entries ?? const <MapEntry<String?, Object?>>[]) {
    final key = entry.key;
    final value = entry.value;
    if (key != null && value != null) {
      result[key] = value;
    }
  }
  return result;
}
