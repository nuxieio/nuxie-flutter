import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nuxie_flutter/nuxie_flutter.dart';

void main() {
  test('instance access before initialize throws', () {
    expect(
      () => Nuxie.instance,
      throwsA(
        isA<NuxieException>().having((e) => e.code, 'code', 'NOT_CONFIGURED'),
      ),
    );
  });

  group('Nuxie', () {
    late _FakePlatform fake;

    setUp(() {
      fake = _FakePlatform();
    });

    tearDown(() async {
      try {
        await Nuxie.instance.shutdown();
      } catch (_) {
        // ignore
      }
      await fake.dispose();
    });

    test('initialize configures the platform and sets singleton', () async {
      final nuxie = await Nuxie.initialize(
        apiKey: 'NX_TEST',
        options: const NuxieOptions(environment: NuxieEnvironment.staging),
        platformOverride: fake,
      );

      expect(identical(nuxie, Nuxie.instance), isTrue);
      expect(fake.lastConfigureApiKey, 'NX_TEST');
      expect(fake.lastConfigureUsingPurchaseController, isFalse);
      expect(fake.lastOptions?.environment, NuxieEnvironment.staging);
      expect(nuxie.isConfigured, isTrue);
    });

    test('initialize is idempotent when already configured', () async {
      final first = await Nuxie.initialize(
        apiKey: 'NX_TEST',
        platformOverride: fake,
      );
      final second = await Nuxie.initialize(
        apiKey: 'NX_TEST_IGNORED',
        platformOverride: fake,
      );

      expect(identical(first, second), isTrue);
      expect(fake.configureCalls, 1);
    });

    test('trigger resolves once a terminal update is emitted', () async {
      final nuxie = await Nuxie.initialize(
        apiKey: 'NX_TEST',
        platformOverride: fake,
      );

      final operation = nuxie.trigger('premium_tapped');
      await _nextTick();

      expect(fake.startedTriggers.length, 1);
      final requestId = fake.startedTriggers.single.requestId;

      final updates = <TriggerUpdate>[];
      final subscription = operation.updates.listen(updates.add);

      fake.emitTrigger(
        NuxieTriggerUpdateEvent(
          requestId: requestId,
          update: TriggerDecisionUpdate(
            TriggerDecisionFlowShown(
              const JourneyRef(
                journeyId: 'j_1',
                campaignId: 'c_1',
                flowId: 'f_1',
              ),
            ),
          ),
          isTerminal: false,
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      const terminal = TriggerDecisionUpdate(TriggerDecisionAllowedImmediate());
      fake.emitTrigger(
        NuxieTriggerUpdateEvent(
          requestId: requestId,
          update: terminal,
          isTerminal: true,
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      final result = await operation.done;
      await subscription.cancel();

      expect(result, terminal);
      expect(updates.length, 2);
      expect(
        updates.last,
        isA<TriggerDecisionUpdate>().having(
          (u) => u.decision,
          'decision',
          isA<TriggerDecisionAllowedImmediate>(),
        ),
      );
    });

    test('cancel forwards to platform and resolves as cancelled terminal error',
        () async {
      final nuxie = await Nuxie.initialize(
        apiKey: 'NX_TEST',
        platformOverride: fake,
      );

      final operation = nuxie.trigger('premium_tapped');
      await _nextTick();
      final requestId = fake.startedTriggers.single.requestId;

      await operation.cancel();
      final result = await operation.done;

      expect(fake.cancelledTriggerRequestIds, contains(requestId));
      expect(
        result,
        isA<TriggerErrorUpdate>().having(
          (u) => u.error.code,
          'code',
          'trigger_cancelled',
        ),
      );
    });

    test('start trigger failures map to trigger_start_failed terminal update',
        () async {
      fake.throwOnStartTrigger = true;
      final nuxie = await Nuxie.initialize(
        apiKey: 'NX_TEST',
        platformOverride: fake,
      );

      final operation = nuxie.trigger('premium_tapped');
      final result = await operation.done;

      expect(
        result,
        isA<TriggerErrorUpdate>().having(
          (u) => u.error.code,
          'code',
          'trigger_start_failed',
        ),
      );
    });

    test(
        'triggerOnce timeout cancels and returns trigger_timeout terminal update',
        () async {
      final nuxie = await Nuxie.initialize(
        apiKey: 'NX_TEST',
        platformOverride: fake,
      );

      final result = await nuxie.triggerOnce(
        'premium_tapped',
        timeout: const Duration(milliseconds: 10),
      );

      expect(
        result,
        isA<TriggerErrorUpdate>().having(
          (u) => u.error.code,
          'code',
          'trigger_timeout',
        ),
      );
      expect(fake.cancelledTriggerRequestIds, hasLength(1));
    });

    test('purchase controller completes purchase and restore requests',
        () async {
      final controller = _RecordingPurchaseController();
      await Nuxie.initialize(
        apiKey: 'NX_TEST',
        purchaseController: controller,
        platformOverride: fake,
      );

      expect(fake.lastConfigureUsingPurchaseController, isTrue);

      fake.emitPurchaseRequest(
        const NuxiePurchaseRequest(
          requestId: 'p_1',
          platform: 'android',
          productId: 'sku_premium',
          timestampMs: 1,
        ),
      );
      fake.emitRestoreRequest(
        const NuxieRestoreRequest(
          requestId: 'r_1',
          platform: 'android',
          timestampMs: 2,
        ),
      );
      await _nextTick();

      expect(controller.purchaseRequests.single.productId, 'sku_premium');
      expect(controller.restoreRequests.single.requestId, 'r_1');
      expect(fake.completedPurchases.single.requestId, 'p_1');
      expect(
        fake.completedPurchases.single.result.type,
        NuxiePurchaseResultType.success,
      );
      expect(fake.completedRestores.single.requestId, 'r_1');
      expect(
        fake.completedRestores.single.result.type,
        NuxieRestoreResultType.success,
      );
    });

    test('purchase controller failures map to failed completion payloads',
        () async {
      final controller = _ThrowingPurchaseController();
      await Nuxie.initialize(
        apiKey: 'NX_TEST',
        purchaseController: controller,
        platformOverride: fake,
      );

      fake.emitPurchaseRequest(
        const NuxiePurchaseRequest(
          requestId: 'p_2',
          platform: 'ios',
          productId: 'sku_premium',
          timestampMs: 1,
        ),
      );
      fake.emitRestoreRequest(
        const NuxieRestoreRequest(
          requestId: 'r_2',
          platform: 'ios',
          timestampMs: 2,
        ),
      );
      await _nextTick();

      expect(fake.completedPurchases.single.requestId, 'p_2');
      expect(
        fake.completedPurchases.single.result.type,
        NuxiePurchaseResultType.failed,
      );
      expect(fake.completedRestores.single.requestId, 'r_2');
      expect(
        fake.completedRestores.single.result.type,
        NuxieRestoreResultType.failed,
      );
    });
  });
}

Future<void> _nextTick() =>
    Future<void>.delayed(const Duration(milliseconds: 1));

class _FakePlatform extends NuxieFlutterPlatform {
  final StreamController<FeatureAccessChangedEvent> _featureChanges =
      StreamController<FeatureAccessChangedEvent>.broadcast();
  final StreamController<NuxieFlowLifecycleEvent> _flowLifecycle =
      StreamController<NuxieFlowLifecycleEvent>.broadcast();
  final StreamController<NuxieLogEvent> _log =
      StreamController<NuxieLogEvent>.broadcast();
  final StreamController<NuxieTriggerUpdateEvent> _triggerUpdates =
      StreamController<NuxieTriggerUpdateEvent>.broadcast();
  final StreamController<NuxiePurchaseRequest> _purchaseRequests =
      StreamController<NuxiePurchaseRequest>.broadcast();
  final StreamController<NuxieRestoreRequest> _restoreRequests =
      StreamController<NuxieRestoreRequest>.broadcast();

  final List<_StartedTriggerCall> startedTriggers = <_StartedTriggerCall>[];
  final List<String> cancelledTriggerRequestIds = <String>[];
  final List<_CompletedPurchase> completedPurchases = <_CompletedPurchase>[];
  final List<_CompletedRestore> completedRestores = <_CompletedRestore>[];

  bool throwOnStartTrigger = false;
  int configureCalls = 0;

  String? lastConfigureApiKey;
  NuxieOptions? lastOptions;
  bool? lastConfigureUsingPurchaseController;
  String? lastWrapperVersion;

  @override
  Stream<FeatureAccessChangedEvent> get featureAccessChanges =>
      _featureChanges.stream;

  @override
  Stream<NuxieFlowLifecycleEvent> get flowLifecycleEvents =>
      _flowLifecycle.stream;

  @override
  Stream<NuxieLogEvent> get logEvents => _log.stream;

  @override
  Stream<NuxieTriggerUpdateEvent> get triggerUpdates => _triggerUpdates.stream;

  @override
  Stream<NuxiePurchaseRequest> get purchaseRequests => _purchaseRequests.stream;

  @override
  Stream<NuxieRestoreRequest> get restoreRequests => _restoreRequests.stream;

  @override
  Future<void> configure({
    required String apiKey,
    NuxieOptions? options,
    required bool usingPurchaseController,
    required String wrapperVersion,
  }) async {
    configureCalls += 1;
    lastConfigureApiKey = apiKey;
    lastOptions = options;
    lastConfigureUsingPurchaseController = usingPurchaseController;
    lastWrapperVersion = wrapperVersion;
  }

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
  }) async {
    if (throwOnStartTrigger) {
      throw const NuxieException(
        code: 'start_failed',
        message: 'start failed',
      );
    }

    startedTriggers.add(
      _StartedTriggerCall(
        requestId: requestId,
        event: event,
      ),
    );
  }

  @override
  Future<void> cancelTrigger(String requestId) async {
    cancelledTriggerRequestIds.add(requestId);
  }

  @override
  Future<void> showFlow(String flowId) async {}

  @override
  Future<ProfileResponse> refreshProfile() async =>
      const ProfileResponse(raw: <String, Object?>{});

  @override
  Future<FeatureAccess> hasFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  }) async {
    return const FeatureAccess(
      allowed: true,
      unlimited: false,
      type: FeatureType.boolean,
    );
  }

  @override
  Future<FeatureAccess?> getCachedFeature(
    String featureId, {
    String? entityId,
  }) async {
    return null;
  }

  @override
  Future<FeatureCheckResult> checkFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  }) async {
    return const FeatureCheckResult(
      customerId: 'c_1',
      featureId: 'f_1',
      requiredBalance: 1,
      code: 'ok',
      allowed: true,
      unlimited: true,
      type: FeatureType.boolean,
    );
  }

  @override
  Future<FeatureCheckResult> refreshFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  }) async {
    return checkFeature(
      featureId,
      requiredBalance: requiredBalance,
      entityId: entityId,
    );
  }

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
  }) async {
    return const FeatureUsageResult(
      success: true,
      featureId: 'f_1',
      amountUsed: 1,
    );
  }

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
  ) async {
    completedPurchases.add(
      _CompletedPurchase(requestId: requestId, result: result),
    );
  }

  @override
  Future<void> completeRestore(
    String requestId,
    NuxieRestoreResult result,
  ) async {
    completedRestores.add(
      _CompletedRestore(requestId: requestId, result: result),
    );
  }

  void emitTrigger(NuxieTriggerUpdateEvent event) {
    _triggerUpdates.add(event);
  }

  void emitPurchaseRequest(NuxiePurchaseRequest request) {
    _purchaseRequests.add(request);
  }

  void emitRestoreRequest(NuxieRestoreRequest request) {
    _restoreRequests.add(request);
  }

  Future<void> dispose() async {
    await _featureChanges.close();
    await _flowLifecycle.close();
    await _log.close();
    await _triggerUpdates.close();
    await _purchaseRequests.close();
    await _restoreRequests.close();
  }
}

class _StartedTriggerCall {
  const _StartedTriggerCall({
    required this.requestId,
    required this.event,
  });

  final String requestId;
  final String event;
}

class _CompletedPurchase {
  const _CompletedPurchase({
    required this.requestId,
    required this.result,
  });

  final String requestId;
  final NuxiePurchaseResult result;
}

class _CompletedRestore {
  const _CompletedRestore({
    required this.requestId,
    required this.result,
  });

  final String requestId;
  final NuxieRestoreResult result;
}

class _RecordingPurchaseController implements NuxiePurchaseController {
  final List<NuxiePurchaseRequest> purchaseRequests = <NuxiePurchaseRequest>[];
  final List<NuxieRestoreRequest> restoreRequests = <NuxieRestoreRequest>[];

  @override
  Future<NuxiePurchaseResult> onPurchase(NuxiePurchaseRequest request) async {
    purchaseRequests.add(request);
    return NuxiePurchaseResult(
      type: NuxiePurchaseResultType.success,
      productId: request.productId,
      purchaseToken: 'tok_123',
    );
  }

  @override
  Future<NuxieRestoreResult> onRestore(NuxieRestoreRequest request) async {
    restoreRequests.add(request);
    return const NuxieRestoreResult(
      type: NuxieRestoreResultType.success,
      restoredCount: 2,
    );
  }
}

class _ThrowingPurchaseController implements NuxiePurchaseController {
  @override
  Future<NuxiePurchaseResult> onPurchase(NuxiePurchaseRequest request) {
    throw Exception('purchase_failed');
  }

  @override
  Future<NuxieRestoreResult> onRestore(NuxieRestoreRequest request) {
    throw Exception('restore_failed');
  }
}
