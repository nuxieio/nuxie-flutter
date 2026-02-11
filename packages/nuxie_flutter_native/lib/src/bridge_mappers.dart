import 'dart:convert';

import 'package:mobile_wrapper_contract/mobile_wrapper_contract.dart';
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
    environment: _environmentToBridge(options.environment),
    apiEndpoint: options.apiEndpoint,
    logLevel: _logLevelToBridge(options.logLevel),
    enableConsoleLogging: options.enableConsoleLogging,
    enableFileLogging: options.enableFileLogging,
    redactSensitiveData: options.redactSensitiveData,
    retryCount: options.retryCount,
    retryDelaySeconds: options.retryDelaySeconds,
    eventBatchSize: options.eventBatchSize,
    flushAt: options.flushAt,
    flushIntervalSeconds: options.flushIntervalSeconds,
    maxQueueSize: options.maxQueueSize,
    maxCacheSizeBytes: options.maxCacheSizeBytes,
    cacheExpirationSeconds: options.cacheExpirationSeconds,
    featureCacheTtlSeconds: options.featureCacheTtlSeconds,
    localeIdentifier: options.localeIdentifier,
    isDebugMode: options.isDebugMode,
    eventLinkingPolicy: _eventLinkingPolicyToBridge(options.eventLinkingPolicy),
    maxFlowCacheSizeBytes: options.maxFlowCacheSizeBytes,
    flowCacheExpirationSeconds: options.flowCacheExpirationSeconds,
    maxConcurrentFlowDownloads: options.maxConcurrentFlowDownloads,
    flowDownloadTimeoutSeconds: options.flowDownloadTimeoutSeconds,
    purchaseTimeoutSeconds: options.purchaseTimeoutSeconds,
  );
}

PTriggerRequest toTriggerRequest(
  String requestId, {
  required String event,
  Map<String, Object?>? properties,
  Map<String, Object?>? userProperties,
  Map<String, Object?>? userPropertiesSetOnce,
}) {
  return PTriggerRequest(
    requestId: requestId,
    event: event,
    properties: properties,
    userProperties: userProperties,
    userPropertiesSetOnce: userPropertiesSetOnce,
  );
}

PPurchaseResult toPurchaseResult(NuxiePurchaseResult result) {
  return PPurchaseResult(
    type: _purchaseTypeToBridge(result.type),
    message: result.message,
    productId: result.productId,
    purchaseToken: result.purchaseToken,
    orderId: result.orderId,
    transactionId: result.transactionId,
    originalTransactionId: result.originalTransactionId,
    transactionJws: result.transactionJws,
  );
}

PRestoreResult toRestoreResult(NuxieRestoreResult result) {
  return PRestoreResult(
    type: _restoreTypeToBridge(result.type),
    restoredCount: result.restoredCount,
    message: result.message,
  );
}

FeatureAccess fromFeatureAccess(PFeatureAccess access) {
  return FeatureAccess(
    allowed: access.allowed ?? false,
    unlimited: access.unlimited ?? false,
    balance: access.balance,
    type: _featureTypeFromBridge(access.type),
  );
}

FeatureCheckResult fromFeatureCheckResult(PFeatureCheckResult result) {
  return FeatureCheckResult(
    customerId: result.customerId ?? '',
    featureId: result.featureId ?? '',
    requiredBalance: result.requiredBalance ?? 1,
    code: result.code ?? '',
    allowed: result.allowed ?? false,
    unlimited: result.unlimited ?? false,
    balance: result.balance,
    type: _featureTypeFromBridge(result.type),
    preview: _jsonFriendly(result.preview),
  );
}

FeatureUsageResult fromFeatureUsageResult(PFeatureUsageResult result) {
  final usageCurrent = result.usageCurrent;
  final usage = usageCurrent == null
      ? null
      : FeatureUsageInfo(
          current: usageCurrent,
          limit: result.usageLimit,
          remaining: result.usageRemaining,
        );
  return FeatureUsageResult(
    success: result.success ?? false,
    featureId: result.featureId ?? '',
    amountUsed: result.amountUsed ?? 0,
    message: result.message,
    usage: usage,
  );
}

ProfileResponse fromProfileResponse(PProfileResponse response) {
  return ProfileResponse(raw: _castStringMap(response.raw));
}

FeatureAccessChangedEvent fromFeatureAccessChangedEvent(
  PFeatureAccessChangedEvent event,
) {
  final to = event.to;
  if (to == null) {
    throw const NuxieException(
      code: 'NATIVE_ERROR',
      message: 'Feature access event missing target payload.',
    );
  }
  return FeatureAccessChangedEvent(
    featureId: event.featureId ?? '',
    from: event.from == null ? null : fromFeatureAccess(event.from!),
    to: fromFeatureAccess(to),
    timestampMs: event.timestampMs,
  );
}

NuxieFlowLifecycleEvent fromFlowLifecycleEvent(PFlowLifecycleEvent event) {
  return NuxieFlowLifecycleEvent(
    type: event.type ?? 'unknown',
    flowId: event.flowId,
    reason: event.reason,
    timestampMs: event.timestampMs,
    payload: _castStringMap(event.payload),
  );
}

NuxieLogEvent fromLogEvent(PLogEvent event) {
  return NuxieLogEvent(
    level: event.level ?? 'debug',
    message: event.message ?? '',
    scope: event.scope,
    timestampMs: event.timestampMs,
  );
}

NuxiePurchaseRequest fromPurchaseRequest(PPurchaseRequest request) {
  return NuxiePurchaseRequest(
    requestId: request.requestId ?? '',
    platform: request.platform ?? 'unknown',
    productId: request.productId ?? '',
    timestampMs: request.timestampMs ?? 0,
    basePlanId: request.basePlanId,
    offerId: request.offerId,
    displayName: request.displayName,
    displayPrice: request.displayPrice,
    price: request.price,
    currencyCode: request.currencyCode,
  );
}

NuxieRestoreRequest fromRestoreRequest(PRestoreRequest request) {
  return NuxieRestoreRequest(
    requestId: request.requestId ?? '',
    platform: request.platform ?? 'unknown',
    timestampMs: request.timestampMs ?? 0,
  );
}

NuxieTriggerUpdateEvent fromTriggerUpdate(PTriggerUpdate event) {
  final update = _triggerUpdateFromBridge(event);
  final isTerminal = event.isTerminal ?? update.isTerminal;

  return NuxieTriggerUpdateEvent(
    requestId: event.requestId ?? '',
    update: update,
    isTerminal: isTerminal,
    timestampMs: event.timestampMs ?? DateTime.now().millisecondsSinceEpoch,
  );
}

TriggerUpdate _triggerUpdateFromBridge(PTriggerUpdate event) {
  final kind = event.updateKind ?? 'error';
  final payload = _castStringMap(event.payload);

  switch (kind) {
    case 'decision':
      return TriggerDecisionUpdate(_triggerDecisionFromPayload(payload));
    case 'entitlement':
      return TriggerEntitlementUpdate(_entitlementFromPayload(payload));
    case 'journey':
      return TriggerJourneyUpdate(_journeyFromPayload(payload));
    case 'error':
      return TriggerErrorUpdate(_errorFromPayload(payload));
    default:
      return TriggerErrorUpdate(
        TriggerError(
          code: 'unknown_trigger_update',
          message: 'Unknown trigger update kind: $kind',
        ),
      );
  }
}

TriggerDecision _triggerDecisionFromPayload(Map<String, Object?> payload) {
  final type = payload['type'] as String? ?? 'no_match';
  switch (type) {
    case 'no_match':
      return const TriggerDecisionNoMatch();
    case 'suppressed':
      return TriggerDecisionSuppressed(_suppressReasonFromPayload(payload));
    case 'journey_started':
      return TriggerDecisionJourneyStarted(_journeyRefFromPayload(payload));
    case 'journey_resumed':
      return TriggerDecisionJourneyResumed(_journeyRefFromPayload(payload));
    case 'flow_shown':
      return TriggerDecisionFlowShown(_journeyRefFromPayload(payload));
    case 'allowed_immediate':
      return const TriggerDecisionAllowedImmediate();
    case 'denied_immediate':
      return const TriggerDecisionDeniedImmediate();
    default:
      return const TriggerDecisionNoMatch();
  }
}

EntitlementUpdate _entitlementFromPayload(Map<String, Object?> payload) {
  final type = payload['type'] as String? ?? 'pending';
  switch (type) {
    case 'allowed':
      return EntitlementAllowed(_gateSourceFromBridge(payload['source'] as String?));
    case 'denied':
      return const EntitlementDenied();
    case 'pending':
    default:
      return const EntitlementPending();
  }
}

JourneyUpdate _journeyFromPayload(Map<String, Object?> payload) {
  return JourneyUpdate(
    journeyId: payload['journeyId'] as String? ?? '',
    campaignId: payload['campaignId'] as String? ?? '',
    flowId: payload['flowId'] as String?,
    exitReason: _journeyExitReasonFromBridge(payload['exitReason'] as String?),
    goalMet: payload['goalMet'] as bool? ?? false,
    goalMetAtEpochMillis: payload['goalMetAtEpochMillis'] as int?,
    durationSeconds: (payload['durationSeconds'] as num?)?.toDouble(),
    flowExitReason: payload['flowExitReason'] as String?,
  );
}

TriggerError _errorFromPayload(Map<String, Object?> payload) {
  return TriggerError(
    code: payload['code'] as String? ?? 'native_error',
    message: payload['message'] as String? ?? 'Unknown native trigger error.',
  );
}

JourneyRef _journeyRefFromPayload(Map<String, Object?> payload) {
  final rawRef = payload['ref'];
  if (rawRef is Map<Object?, Object?>) {
    final ref = _castUnknownMap(rawRef);
    return JourneyRef(
      journeyId: ref['journeyId'] as String? ?? '',
      campaignId: ref['campaignId'] as String? ?? '',
      flowId: ref['flowId'] as String?,
    );
  }

  return JourneyRef(
    journeyId: payload['journeyId'] as String? ?? '',
    campaignId: payload['campaignId'] as String? ?? '',
    flowId: payload['flowId'] as String?,
  );
}

SuppressReason _suppressReasonFromPayload(Map<String, Object?> payload) {
  final value = payload['reason'] as String? ?? payload['rawReason'] as String?;
  switch (value) {
    case 'already_active':
      return SuppressReason.alreadyActive;
    case 'reentry_limited':
      return SuppressReason.reentryLimited;
    case 'holdout':
      return SuppressReason.holdout;
    case 'no_flow':
      return SuppressReason.noFlow;
    default:
      return SuppressReason.unknown;
  }
}

Map<String, Object?> _castStringMap(Map<String?, Object?>? map) {
  if (map == null || map.isEmpty) {
    return <String, Object?>{};
  }
  return map.map(
    (key, value) => MapEntry(
      key ?? '',
      _jsonFriendly(value),
    ),
  );
}

Map<String, Object?> _castUnknownMap(Map<Object?, Object?> map) {
  if (map.isEmpty) {
    return <String, Object?>{};
  }
  return map.map(
    (key, value) => MapEntry(
      key?.toString() ?? '',
      _jsonFriendly(value),
    ),
  );
}

Object? _jsonFriendly(Object? value) {
  if (value == null) return null;
  if (value is String || value is num || value is bool) {
    return value;
  }

  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(
        key?.toString() ?? '',
        _jsonFriendly(nestedValue),
      ),
    );
  }

  if (value is Iterable) {
    return value.map(_jsonFriendly).toList(growable: false);
  }

  try {
    return json.decode(json.encode(value));
  } catch (_) {
    return value.toString();
  }
}

String _environmentToBridge(NuxieEnvironment environment) {
  switch (environment) {
    case NuxieEnvironment.production:
      return 'production';
    case NuxieEnvironment.staging:
      return 'staging';
    case NuxieEnvironment.development:
      return 'development';
    case NuxieEnvironment.custom:
      return 'custom';
  }
}

String? _logLevelToBridge(NuxieLogLevel? level) {
  switch (level) {
    case null:
      return null;
    case NuxieLogLevel.verbose:
      return 'verbose';
    case NuxieLogLevel.debug:
      return 'debug';
    case NuxieLogLevel.info:
      return 'info';
    case NuxieLogLevel.warning:
      return 'warning';
    case NuxieLogLevel.error:
      return 'error';
    case NuxieLogLevel.none:
      return 'none';
  }
}

String? _eventLinkingPolicyToBridge(NuxieEventLinkingPolicy? policy) {
  switch (policy) {
    case null:
      return null;
    case NuxieEventLinkingPolicy.keepSeparate:
      return 'keep_separate';
    case NuxieEventLinkingPolicy.migrateOnIdentify:
      return 'migrate_on_identify';
  }
}

String _purchaseTypeToBridge(NuxiePurchaseResultType type) {
  switch (type) {
    case NuxiePurchaseResultType.success:
      return 'success';
    case NuxiePurchaseResultType.cancelled:
      return 'cancelled';
    case NuxiePurchaseResultType.pending:
      return 'pending';
    case NuxiePurchaseResultType.failed:
      return 'failed';
  }
}

String _restoreTypeToBridge(NuxieRestoreResultType type) {
  switch (type) {
    case NuxieRestoreResultType.success:
      return 'success';
    case NuxieRestoreResultType.noPurchases:
      return 'no_purchases';
    case NuxieRestoreResultType.failed:
      return 'failed';
  }
}

FeatureType _featureTypeFromBridge(String? type) {
  switch (type) {
    case 'metered':
      return FeatureType.metered;
    case 'creditSystem':
    case 'credit_system':
      return FeatureType.creditSystem;
    case 'boolean':
    default:
      return FeatureType.boolean;
  }
}

GateSourceKind _gateSourceFromBridge(String? source) {
  switch (source) {
    case 'purchase':
      return GateSourceKind.purchase;
    case 'restore':
      return GateSourceKind.restore;
    case 'cache':
    default:
      return GateSourceKind.cache;
  }
}

JourneyExitReasonKind _journeyExitReasonFromBridge(String? reason) {
  switch (reason) {
    case 'goal_met':
      return JourneyExitReasonKind.goalMet;
    case 'trigger_unmatched':
      return JourneyExitReasonKind.triggerUnmatched;
    case 'expired':
      return JourneyExitReasonKind.expired;
    case 'error':
      return JourneyExitReasonKind.error;
    case 'cancelled':
      return JourneyExitReasonKind.cancelled;
    case 'completed':
    default:
      return JourneyExitReasonKind.completed;
  }
}
