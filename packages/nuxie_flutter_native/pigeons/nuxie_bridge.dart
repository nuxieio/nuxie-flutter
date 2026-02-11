import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/generated/nuxie_bridge.g.dart',
    dartOptions: DartOptions(),
    dartPackageName: 'nuxie_flutter_native',
    kotlinOut:
        'android/src/main/kotlin/io/nuxie/flutter/nativeplugin/NuxieBridge.g.kt',
    kotlinOptions: KotlinOptions(package: 'io.nuxie.flutter.nativeplugin'),
    swiftOut: 'ios/Classes/NuxieBridge.g.swift',
    swiftOptions: SwiftOptions(),
  ),
)
class PConfigureRequest {
  String apiKey = '';
  String wrapperVersion = '';
  bool usingPurchaseController = false;
  String environment = 'production';
  String? apiEndpoint;
  String? logLevel;
  bool? enableConsoleLogging;
  bool? enableFileLogging;
  bool? redactSensitiveData;
  int? retryCount;
  int? retryDelaySeconds;
  int? eventBatchSize;
  int? flushAt;
  int? flushIntervalSeconds;
  int? maxQueueSize;
  int? maxCacheSizeBytes;
  int? cacheExpirationSeconds;
  int? featureCacheTtlSeconds;
  String? localeIdentifier;
  bool? isDebugMode;
  String? eventLinkingPolicy;
  int? maxFlowCacheSizeBytes;
  int? flowCacheExpirationSeconds;
  int? maxConcurrentFlowDownloads;
  int? flowDownloadTimeoutSeconds;
}

class PTriggerRequest {
  String requestId = '';
  String event = '';
  Map<String?, Object?>? properties;
  Map<String?, Object?>? userProperties;
  Map<String?, Object?>? userPropertiesSetOnce;
}

class PTriggerUpdate {
  String requestId = '';
  String updateKind = '';
  Map<String?, Object?> payload = <String?, Object?>{};
  bool isTerminal = false;
  int timestampMs = 0;
}

class PFeatureAccess {
  bool allowed = false;
  bool unlimited = false;
  int? balance;
  String type = 'boolean';
}

class PFeatureCheckResult {
  String customerId = '';
  String featureId = '';
  int requiredBalance = 1;
  String code = '';
  bool allowed = false;
  bool unlimited = false;
  int? balance;
  String type = 'boolean';
  Object? preview;
}

class PFeatureUsageResult {
  bool success = false;
  String featureId = '';
  double amountUsed = 0;
  String? message;
  double? usageCurrent;
  double? usageLimit;
  double? usageRemaining;
}

class PProfileResponse {
  Map<String?, Object?> raw = <String?, Object?>{};
}

class PFeatureAccessChangedEvent {
  String featureId = '';
  PFeatureAccess? from;
  PFeatureAccess to = PFeatureAccess();
  int timestampMs = 0;
}

class PFlowLifecycleEvent {
  String type = '';
  String? flowId;
  String? reason;
  int timestampMs = 0;
}

class PLogEvent {
  String level = '';
  String message = '';
  String? scope;
  int timestampMs = 0;
}

class PPurchaseRequest {
  String requestId = '';
  String platform = '';
  String productId = '';
  String? basePlanId;
  String? offerId;
  String? displayName;
  String? displayPrice;
  double? price;
  String? currencyCode;
  int timestampMs = 0;
}

class PRestoreRequest {
  String requestId = '';
  String platform = '';
  int timestampMs = 0;
}

class PPurchaseResult {
  String type = '';
  String? message;
  String? productId;
  String? purchaseToken;
  String? orderId;
  String? transactionId;
  String? originalTransactionId;
  String? transactionJws;
}

class PRestoreResult {
  String type = '';
  int? restoredCount;
  String? message;
}

@HostApi()
abstract class PNuxieHostApi {
  @async
  void configure(PConfigureRequest request);

  @async
  void shutdown();

  @async
  void identify(
    String distinctId,
    Map<String?, Object?>? userProperties,
    Map<String?, Object?>? userPropertiesSetOnce,
  );

  @async
  void reset(bool keepAnonymousId);

  @async
  String getDistinctId();

  @async
  String getAnonymousId();

  @async
  bool getIsIdentified();

  @async
  void startTrigger(PTriggerRequest request);

  @async
  void cancelTrigger(String requestId);

  @async
  void showFlow(String flowId);

  @async
  PProfileResponse refreshProfile();

  @async
  PFeatureAccess hasFeature(
      String featureId, int? requiredBalance, String? entityId);

  @async
  PFeatureAccess? getCachedFeature(String featureId, String? entityId);

  @async
  PFeatureCheckResult checkFeature(
      String featureId, int? requiredBalance, String? entityId);

  @async
  PFeatureCheckResult refreshFeature(
      String featureId, int? requiredBalance, String? entityId);

  @async
  void useFeature(String featureId, double amount, String? entityId,
      Map<String?, Object?>? metadata);

  @async
  PFeatureUsageResult useFeatureAndWait(
    String featureId,
    double amount,
    String? entityId,
    bool setUsage,
    Map<String?, Object?>? metadata,
  );

  @async
  bool flushEvents();

  @async
  int getQueuedEventCount();

  @async
  void pauseEventQueue();

  @async
  void resumeEventQueue();

  @async
  void completePurchase(String requestId, PPurchaseResult result);

  @async
  void completeRestore(String requestId, PRestoreResult result);
}

@FlutterApi()
abstract class PNuxieFlutterApi {
  void onTriggerUpdate(PTriggerUpdate event);

  void onFeatureAccessChanged(PFeatureAccessChangedEvent event);

  void onFlowLifecycle(PFlowLifecycleEvent event);

  void onLog(PLogEvent event);

  void onPurchaseRequest(PPurchaseRequest request);

  void onRestoreRequest(PRestoreRequest request);
}
