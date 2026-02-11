import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nuxie_flutter/nuxie_flutter.dart';
import 'package:nuxie_flutter_example/main.dart';

void main() {
  tearDown(() async {
    try {
      await Nuxie.instance.shutdown();
    } catch (_) {
      // Ignore when the singleton was not initialized by a test.
    }
  });

  testWidgets('renders nuxie example controls', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Nuxie Flutter Example'), findsOneWidget);
    expect(find.text('Initialize'), findsOneWidget);
    expect(find.text('Identify'), findsOneWidget);
    expect(find.text('Trigger'), findsOneWidget);
    expect(find.text('Show Flow'), findsOneWidget);
    expect(find.text('Run Sanity Check'), findsOneWidget);
  });

  testWidgets('runs sanity check end-to-end with fake platform',
      (WidgetTester tester) async {
    final fakePlatform = _FakePlatform();
    addTearDown(fakePlatform.dispose);

    await tester.pumpWidget(
      ExampleApp(platformOverride: fakePlatform),
    );

    await tester.tap(find.text('Run Sanity Check'));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.textContaining('sanity: passed'), findsOneWidget);
    expect(fakePlatform.identifyCount, greaterThan(0));
    expect(fakePlatform.triggerCount, greaterThan(0));
    expect(fakePlatform.flushCount, greaterThan(0));
  });
}

class _FakePlatform extends NuxieFlutterPlatform {
  final StreamController<FeatureAccessChangedEvent> _featureChanges =
      StreamController<FeatureAccessChangedEvent>.broadcast();
  final StreamController<NuxieFlowLifecycleEvent> _flowLifecycle =
      StreamController<NuxieFlowLifecycleEvent>.broadcast();
  final StreamController<NuxieLogEvent> _logs =
      StreamController<NuxieLogEvent>.broadcast();
  final StreamController<NuxieTriggerUpdateEvent> _triggerUpdates =
      StreamController<NuxieTriggerUpdateEvent>.broadcast();
  final StreamController<NuxiePurchaseRequest> _purchaseRequests =
      StreamController<NuxiePurchaseRequest>.broadcast();
  final StreamController<NuxieRestoreRequest> _restoreRequests =
      StreamController<NuxieRestoreRequest>.broadcast();

  int identifyCount = 0;
  int triggerCount = 0;
  int flushCount = 0;

  @override
  Stream<FeatureAccessChangedEvent> get featureAccessChanges =>
      _featureChanges.stream;

  @override
  Stream<NuxieFlowLifecycleEvent> get flowLifecycleEvents =>
      _flowLifecycle.stream;

  @override
  Stream<NuxieLogEvent> get logEvents => _logs.stream;

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
  }) async {}

  @override
  Future<void> shutdown() async {}

  @override
  Future<void> identify(
    String distinctId, {
    Map<String, Object?>? userProperties,
    Map<String, Object?>? userPropertiesSetOnce,
  }) async {
    identifyCount += 1;
  }

  @override
  Future<void> reset({bool keepAnonymousId = true}) async {}

  @override
  Future<String> getDistinctId() async => 'user_123';

  @override
  Future<String> getAnonymousId() async => 'anon_123';

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
    triggerCount += 1;
    _triggerUpdates.add(
      NuxieTriggerUpdateEvent(
        requestId: requestId,
        update: TriggerDecisionUpdate(
          TriggerDecisionFlowShown(
            const JourneyRef(
              journeyId: 'journey_123',
              campaignId: 'campaign_123',
              flowId: 'flow_123',
            ),
          ),
        ),
        isTerminal: false,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    _triggerUpdates.add(
      NuxieTriggerUpdateEvent(
        requestId: requestId,
        update: const TriggerDecisionUpdate(
          TriggerDecisionAllowedImmediate(),
        ),
        isTerminal: true,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<void> cancelTrigger(String requestId) async {}

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
      balance: 42,
      type: FeatureType.metered,
    );
  }

  @override
  Future<FeatureAccess?> getCachedFeature(
    String featureId, {
    String? entityId,
  }) async {
    return const FeatureAccess(
      allowed: true,
      unlimited: false,
      balance: 42,
      type: FeatureType.metered,
    );
  }

  @override
  Future<FeatureCheckResult> checkFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  }) async {
    return const FeatureCheckResult(
      customerId: 'customer_123',
      featureId: 'premium_feature',
      requiredBalance: 1,
      code: 'ok',
      allowed: true,
      unlimited: false,
      balance: 42,
      type: FeatureType.metered,
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
      featureId: 'premium_feature',
      amountUsed: 1,
      message: 'ok',
    );
  }

  @override
  Future<bool> flushEvents() async {
    flushCount += 1;
    return true;
  }

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

  Future<void> dispose() async {
    await _featureChanges.close();
    await _flowLifecycle.close();
    await _logs.close();
    await _triggerUpdates.close();
    await _purchaseRequests.close();
    await _restoreRequests.close();
  }
}
