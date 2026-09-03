import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/generated/nuxie_bridge.g.dart',
    dartOptions: DartOptions(),
    dartPackageName: 'nuxie_flutter_native',
    kotlinOut:
        'android/src/main/kotlin/io/nuxie/flutter/nativeplugin/NuxieBridge.g.kt',
    kotlinOptions: KotlinOptions(package: 'io.nuxie.flutter.nativeplugin'),
    swiftOut:
        'ios/nuxie_flutter_native/Sources/nuxie_flutter_native/NuxieBridge.g.swift',
    swiftOptions: SwiftOptions(),
  ),
)
class PConfigureRequest {
  String? apiKey;
  String? wrapperVersion;
  bool? usingPurchaseController;
  String? environment;
  String? logLevel;
  bool? enableConsoleLogging;
  bool? redactSensitiveData;
  String? localeIdentifier;
  String? purchaseHandlingMode;
  bool? testStoreEnabled;
}

class PFeatureAccess {
  bool? allowed;
  bool? unlimited;
  double? balance;
  String? type;
}

class PFeatureUsageResult {
  bool? success;
  String? featureId;
  double? amountUsed;
  String? message;
  double? usageCurrent;
  double? usageLimit;
  double? usageRemaining;
  PFeatureAccess? authoritativeAccess;
}

class PFeatureAccessChangedEvent {
  String? featureId;
  PFeatureAccess? from;
  PFeatureAccess? to;
  int? timestampMs;
}

class PExperienceRef {
  String? experienceId;
  String? experienceVersion;
  String? journeyId;
}

class PAppAction {
  String? name;
  Map<String?, Object?>? payload;
  PExperienceRef? experience;
}

class PActivityInfo {
  int? schemaVersion;
  String? id;
  int? timestampMs;
  int? receivedAtMs;
  String? name;
  Map<String?, Object?>? properties;
}

class PPurchaseRequest {
  String? requestId;
  String? platform;
  String? productId;
  String? storeProductId;
  String? basePlanId;
  String? purchaseOptionId;
  String? offerId;
  String? placementId;
  String? displayName;
  String? displayPrice;
  int? timestampMs;
}

class PRestoreRequest {
  String? requestId;
  String? platform;
  int? timestampMs;
}

class PPurchaseResult {
  String? type;
  String? message;
}

class PRestoreResult {
  String? type;
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

  void trigger(String event, Map<String?, Object?>? properties);

  @async
  void dismiss();

  @async
  void setLocaleIdentifier(String? localeIdentifier);

  @async
  PFeatureAccess hasFeature(
    String featureId,
    double requiredBalance,
    String? entityId,
    String policy,
  );

  void useFeature(
    String featureId,
    double amount,
    String? entityId,
    Map<String?, Object?>? metadata,
  );

  @async
  PFeatureUsageResult useFeatureAndWait(
    String featureId,
    double amount,
    String? entityId,
    bool setUsage,
    Map<String?, Object?>? metadata,
  );

  void completePurchase(String requestId, PPurchaseResult result);

  void completeRestore(String requestId, PRestoreResult result);
}

@FlutterApi()
abstract class PNuxieFlutterApi {
  void onFeatureAccessChanged(PFeatureAccessChangedEvent event);

  void onActivity(PActivityInfo activity);

  void onAppAction(PAppAction action);

  void onPurchaseRequest(PPurchaseRequest request);

  void onRestoreRequest(PRestoreRequest request);
}
