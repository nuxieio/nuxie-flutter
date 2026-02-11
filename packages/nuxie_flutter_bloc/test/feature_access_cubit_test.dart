import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nuxie_flutter/nuxie_flutter.dart';
import 'package:nuxie_flutter_bloc/nuxie_flutter_bloc.dart';

void main() {
  late _FakePlatform platform;

  setUp(() {
    platform = _FakePlatform();
  });

  tearDown(() async {
    try {
      await Nuxie.instance.shutdown();
    } catch (_) {
      // ignore when not initialized
    }
    await platform.dispose();
  });

  test('FeatureAccessCubit refreshes and reacts to native feature events',
      () async {
    await Nuxie.initialize(
      apiKey: 'NX_TEST',
      platformOverride: platform,
    );

    final cubit = FeatureAccessCubit(
      Nuxie.instance,
      'pro_feature',
    );
    addTearDown(cubit.close);

    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(
      cubit.state,
      const FeatureAccess(
        allowed: true,
        unlimited: false,
        balance: 5,
        type: FeatureType.metered,
      ),
    );

    platform.emitFeatureChange(
      const FeatureAccessChangedEvent(
        featureId: 'pro_feature',
        to: FeatureAccess(
          allowed: false,
          unlimited: false,
          balance: 0,
          type: FeatureType.boolean,
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(
      cubit.state,
      const FeatureAccess(
        allowed: false,
        unlimited: false,
        balance: 0,
        type: FeatureType.boolean,
      ),
    );
  });
}

class _FakePlatform extends NuxieFlutterPlatform {
  final StreamController<FeatureAccessChangedEvent> _featureChanges =
      StreamController<FeatureAccessChangedEvent>.broadcast();

  @override
  Stream<FeatureAccessChangedEvent> get featureAccessChanges =>
      _featureChanges.stream;

  @override
  Stream<NuxieFlowLifecycleEvent> get flowLifecycleEvents =>
      const Stream<NuxieFlowLifecycleEvent>.empty();

  @override
  Stream<NuxieLogEvent> get logEvents => const Stream<NuxieLogEvent>.empty();

  @override
  Stream<NuxieTriggerUpdateEvent> get triggerUpdates =>
      const Stream<NuxieTriggerUpdateEvent>.empty();

  @override
  Stream<NuxiePurchaseRequest> get purchaseRequests =>
      const Stream<NuxiePurchaseRequest>.empty();

  @override
  Stream<NuxieRestoreRequest> get restoreRequests =>
      const Stream<NuxieRestoreRequest>.empty();

  void emitFeatureChange(FeatureAccessChangedEvent event) {
    _featureChanges.add(event);
  }

  Future<void> dispose() => _featureChanges.close();

  @override
  Future<FeatureAccess> hasFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  }) async {
    return const FeatureAccess(
      allowed: true,
      unlimited: false,
      balance: 5,
      type: FeatureType.metered,
    );
  }

  @override
  Future<void> configure({
    required String apiKey,
    NuxieOptions? options,
    required bool usingPurchaseController,
    required String wrapperVersion,
  }) async {}

  @override
  Future<void> shutdown() async {}

  @override
  Future<void> identify(
    String distinctId, {
    Map<String, Object?>? userProperties,
    Map<String, Object?>? userPropertiesSetOnce,
  }) async {}

  @override
  Future<void> reset({bool keepAnonymousId = true}) async {}

  @override
  Future<String> getDistinctId() async => 'distinct';

  @override
  Future<String> getAnonymousId() async => 'anon';

  @override
  Future<bool> getIsIdentified() async => true;

  @override
  Future<void> startTrigger(
    String requestId, {
    required String event,
    Map<String, Object?>? properties,
    Map<String, Object?>? userProperties,
    Map<String, Object?>? userPropertiesSetOnce,
  }) async {}

  @override
  Future<void> cancelTrigger(String requestId) async {}

  @override
  Future<void> showFlow(String flowId) async {}

  @override
  Future<ProfileResponse> refreshProfile() async =>
      const ProfileResponse(raw: <String, Object?>{});

  @override
  Future<FeatureAccess?> getCachedFeature(
    String featureId, {
    String? entityId,
  }) async =>
      null;

  @override
  Future<FeatureCheckResult> checkFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  }) async =>
      const FeatureCheckResult(
        customerId: 'c_1',
        featureId: 'f_1',
        requiredBalance: 1,
        code: 'ok',
        allowed: true,
        unlimited: true,
        type: FeatureType.boolean,
      );

  @override
  Future<FeatureCheckResult> refreshFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  }) async =>
      const FeatureCheckResult(
        customerId: 'c_1',
        featureId: 'f_1',
        requiredBalance: 1,
        code: 'ok',
        allowed: true,
        unlimited: true,
        type: FeatureType.boolean,
      );

  @override
  Future<void> useFeature(
    String featureId, {
    double amount = 1,
    String? entityId,
    Map<String, Object?>? metadata,
  }) async {}

  @override
  Future<FeatureUsageResult> useFeatureAndWait(
    String featureId, {
    double amount = 1,
    String? entityId,
    bool setUsage = false,
    Map<String, Object?>? metadata,
  }) async =>
      const FeatureUsageResult(
        success: true,
        featureId: 'f_1',
        amountUsed: 1,
      );

  @override
  Future<bool> flushEvents() async => true;

  @override
  Future<int> getQueuedEventCount() async => 0;

  @override
  Future<void> pauseEventQueue() async {}

  @override
  Future<void> resumeEventQueue() async {}

  @override
  Future<void> completePurchase(
    String requestId,
    NuxiePurchaseResult result,
  ) async {}

  @override
  Future<void> completeRestore(
    String requestId,
    NuxieRestoreResult result,
  ) async {}
}
