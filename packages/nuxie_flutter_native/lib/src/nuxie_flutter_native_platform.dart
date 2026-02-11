import 'package:nuxie_flutter_platform_interface/nuxie_flutter_platform_interface.dart';

class NuxieFlutterNativePlatform {
  static void registerWith() {
    NuxieFlutterPlatform.instance = NuxieFlutterNativePlatformImpl();
  }
}

class NuxieFlutterNativePlatformImpl extends NuxieFlutterPlatform {
  @override
  Future<void> cancelTrigger(String requestId) {
    throw UnimplementedError();
  }

  @override
  Future<FeatureCheckResult> checkFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> completePurchase(String requestId, NuxiePurchaseResult result) {
    throw UnimplementedError();
  }

  @override
  Future<void> completeRestore(String requestId, NuxieRestoreResult result) {
    throw UnimplementedError();
  }

  @override
  Future<void> configure({
    required String apiKey,
    NuxieOptions? options,
    required bool usingPurchaseController,
    required String wrapperVersion,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<FeatureAccessChangedEvent> get featureAccessChanges =>
      const Stream.empty();

  @override
  Future<bool> flushEvents() {
    throw UnimplementedError();
  }

  @override
  Future<String> getAnonymousId() {
    throw UnimplementedError();
  }

  @override
  Future<FeatureAccess?> getCachedFeature(String featureId,
      {String? entityId}) {
    throw UnimplementedError();
  }

  @override
  Future<String> getDistinctId() {
    throw UnimplementedError();
  }

  @override
  Stream<NuxieFlowLifecycleEvent> get flowLifecycleEvents =>
      const Stream.empty();

  @override
  Future<bool> getIsIdentified() {
    throw UnimplementedError();
  }

  @override
  Future<int> getQueuedEventCount() {
    throw UnimplementedError();
  }

  @override
  Future<FeatureAccess> hasFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> identify(
    String distinctId, {
    Map<String, Object?>? userProperties,
    Map<String, Object?>? userPropertiesSetOnce,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<NuxieLogEvent> get logEvents => const Stream.empty();

  @override
  Future<void> pauseEventQueue() {
    throw UnimplementedError();
  }

  @override
  Future<ProfileResponse> refreshProfile() {
    throw UnimplementedError();
  }

  @override
  Future<FeatureCheckResult> refreshFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> reset({bool keepAnonymousId = true}) {
    throw UnimplementedError();
  }

  @override
  Future<void> resumeEventQueue() {
    throw UnimplementedError();
  }

  @override
  Future<void> showFlow(String flowId) {
    throw UnimplementedError();
  }

  @override
  Future<void> shutdown() {
    throw UnimplementedError();
  }

  @override
  Future<void> startTrigger(
    String requestId, {
    required String event,
    Map<String, Object?>? properties,
    Map<String, Object?>? userProperties,
    Map<String, Object?>? userPropertiesSetOnce,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<NuxieTriggerUpdateEvent> get triggerUpdates => const Stream.empty();

  @override
  Future<void> useFeature(
    String featureId, {
    double amount = 1,
    String? entityId,
    Map<String, Object?>? metadata,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<FeatureUsageResult> useFeatureAndWait(
    String featureId, {
    double amount = 1,
    String? entityId,
    bool setUsage = false,
    Map<String, Object?>? metadata,
  }) {
    throw UnimplementedError();
  }
}
