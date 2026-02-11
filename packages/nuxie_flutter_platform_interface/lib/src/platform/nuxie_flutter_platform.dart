import 'dart:async';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../events/nuxie_events.dart';
import '../models/feature_models.dart';
import '../models/nuxie_options.dart';
import '../models/profile_models.dart';
import '../models/purchase_models.dart';

abstract class NuxieFlutterPlatform extends PlatformInterface {
  NuxieFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static NuxieFlutterPlatform _instance = _UnsupportedNuxieFlutterPlatform();

  static NuxieFlutterPlatform get instance => _instance;

  static set instance(NuxieFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<FeatureAccessChangedEvent> get featureAccessChanges;

  Stream<NuxieFlowLifecycleEvent> get flowLifecycleEvents;

  Stream<NuxieLogEvent> get logEvents;

  Stream<NuxieTriggerUpdateEvent> get triggerUpdates;

  Future<void> configure({
    required String apiKey,
    NuxieOptions? options,
    required bool usingPurchaseController,
    required String wrapperVersion,
  });

  Future<void> shutdown();

  Future<void> identify(
    String distinctId, {
    Map<String, Object?>? userProperties,
    Map<String, Object?>? userPropertiesSetOnce,
  });

  Future<void> reset({bool keepAnonymousId = true});

  Future<String> getDistinctId();

  Future<String> getAnonymousId();

  Future<bool> getIsIdentified();

  Future<void> startTrigger(
    String requestId, {
    required String event,
    Map<String, Object?>? properties,
    Map<String, Object?>? userProperties,
    Map<String, Object?>? userPropertiesSetOnce,
  });

  Future<void> cancelTrigger(String requestId);

  Future<void> showFlow(String flowId);

  Future<ProfileResponse> refreshProfile();

  Future<FeatureAccess> hasFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  });

  Future<FeatureAccess?> getCachedFeature(
    String featureId, {
    String? entityId,
  });

  Future<FeatureCheckResult> checkFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  });

  Future<FeatureCheckResult> refreshFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  });

  Future<void> useFeature(
    String featureId, {
    double amount = 1,
    String? entityId,
    Map<String, Object?>? metadata,
  });

  Future<FeatureUsageResult> useFeatureAndWait(
    String featureId, {
    double amount = 1,
    String? entityId,
    bool setUsage = false,
    Map<String, Object?>? metadata,
  });

  Future<bool> flushEvents();

  Future<int> getQueuedEventCount();

  Future<void> pauseEventQueue();

  Future<void> resumeEventQueue();

  Future<void> completePurchase(
    String requestId,
    NuxiePurchaseResult result,
  );

  Future<void> completeRestore(
    String requestId,
    NuxieRestoreResult result,
  );
}

class _UnsupportedNuxieFlutterPlatform extends NuxieFlutterPlatform {
  _UnsupportedNuxieFlutterPlatform() : super();

  Never _unimplemented() {
    throw UnimplementedError(
      'No nuxie_flutter platform implementation has been registered.',
    );
  }

  @override
  Stream<FeatureAccessChangedEvent> get featureAccessChanges =>
      const Stream<FeatureAccessChangedEvent>.empty();

  @override
  Stream<NuxieFlowLifecycleEvent> get flowLifecycleEvents =>
      const Stream<NuxieFlowLifecycleEvent>.empty();

  @override
  Stream<NuxieLogEvent> get logEvents => const Stream<NuxieLogEvent>.empty();

  @override
  Stream<NuxieTriggerUpdateEvent> get triggerUpdates =>
      const Stream<NuxieTriggerUpdateEvent>.empty();

  @override
  Future<void> cancelTrigger(String requestId) async => _unimplemented();

  @override
  Future<FeatureCheckResult> checkFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  }) async =>
      _unimplemented();

  @override
  Future<void> completePurchase(
          String requestId, NuxiePurchaseResult result) async =>
      _unimplemented();

  @override
  Future<void> completeRestore(
          String requestId, NuxieRestoreResult result) async =>
      _unimplemented();

  @override
  Future<void> configure({
    required String apiKey,
    NuxieOptions? options,
    required bool usingPurchaseController,
    required String wrapperVersion,
  }) async =>
      _unimplemented();

  @override
  Future<void> identify(
    String distinctId, {
    Map<String, Object?>? userProperties,
    Map<String, Object?>? userPropertiesSetOnce,
  }) async =>
      _unimplemented();

  @override
  Future<void> pauseEventQueue() async => _unimplemented();

  @override
  Future<void> reset({bool keepAnonymousId = true}) async => _unimplemented();

  @override
  Future<void> resumeEventQueue() async => _unimplemented();

  @override
  Future<ProfileResponse> refreshProfile() async => _unimplemented();

  @override
  Future<FeatureCheckResult> refreshFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  }) async =>
      _unimplemented();

  @override
  Future<void> showFlow(String flowId) async => _unimplemented();

  @override
  Future<void> shutdown() async => _unimplemented();

  @override
  Future<void> startTrigger(
    String requestId, {
    required String event,
    Map<String, Object?>? properties,
    Map<String, Object?>? userProperties,
    Map<String, Object?>? userPropertiesSetOnce,
  }) async =>
      _unimplemented();

  @override
  Future<void> useFeature(
    String featureId, {
    double amount = 1,
    String? entityId,
    Map<String, Object?>? metadata,
  }) async =>
      _unimplemented();

  @override
  Future<FeatureUsageResult> useFeatureAndWait(
    String featureId, {
    double amount = 1,
    String? entityId,
    bool setUsage = false,
    Map<String, Object?>? metadata,
  }) async =>
      _unimplemented();

  @override
  Future<bool> flushEvents() async => _unimplemented();

  @override
  Future<String> getAnonymousId() async => _unimplemented();

  @override
  Future<FeatureAccess?> getCachedFeature(
    String featureId, {
    String? entityId,
  }) async =>
      _unimplemented();

  @override
  Future<String> getDistinctId() async => _unimplemented();

  @override
  Future<bool> getIsIdentified() async => _unimplemented();

  @override
  Future<int> getQueuedEventCount() async => _unimplemented();

  @override
  Future<FeatureAccess> hasFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  }) async =>
      _unimplemented();
}
