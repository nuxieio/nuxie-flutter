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
        // No configured singleton remains.
      }
      await fake.dispose();
    });

    test('initialize forwards only the compact configuration', () async {
      final nuxie = await Nuxie.initialize(
        apiKey: 'NX_TEST',
        options: const NuxieOptions(
          environment: NuxieEnvironment.development,
          purchaseHandlingMode: PurchaseHandlingMode.observer,
        ),
        platformOverride: fake,
      );

      expect(identical(nuxie, Nuxie.instance), isTrue);
      expect(fake.apiKey, 'NX_TEST');
      expect(fake.options?.environment, NuxieEnvironment.development);
      expect(fake.usingPurchaseController, isFalse);
    });

    test(
      'trigger is event-only and reset defaults to a fresh anonymous id',
      () async {
        final nuxie = await Nuxie.initialize(
          apiKey: 'NX_TEST',
          platformOverride: fake,
        );

        expect(
          () => nuxie.trigger(
            'premium_tapped',
            properties: <String, Object?>{'source': 'settings'},
          ),
          returnsNormally,
        );
        await nuxie.reset();

        expect(fake.events.single.event, 'premium_tapped');
        expect(fake.events.single.properties?['source'], 'settings');
        expect(fake.resetValues, <bool>[false]);
      },
    );

    test(
      'Feature APIs preserve policy, fractions, and authoritative access',
      () async {
        final nuxie = await Nuxie.initialize(
          apiKey: 'NX_TEST',
          platformOverride: fake,
        );

        final access = await nuxie.hasFeature(
          'credits',
          requiredBalance: 2.5,
          entityId: 'workspace-1',
          policy: FeatureCheckPolicy.remote,
        );
        final usage = await nuxie.useFeatureAndWait('credits', amount: 1.5);

        expect(access.balance, 3.5);
        expect(fake.featurePolicy, FeatureCheckPolicy.remote);
        expect(fake.requiredBalance, 2.5);
        expect(usage.authoritativeAccess?.balance, 8);
      },
    );

    test('typed activity and App Action streams are exposed', () async {
      final nuxie = await Nuxie.initialize(
        apiKey: 'NX_TEST',
        platformOverride: fake,
      );
      final activity = nuxie.activities.first;
      final action = nuxie.appActions.first;

      fake.emitActivity(
        const NuxieActivityInfo(
          schemaVersion: 1,
          id: 'event-1',
          timestampMs: 1,
          receivedAtMs: 2,
          name: r'$journey_leg_started',
          properties: <String, Object>{'journey_id': 'journey-1'},
        ),
      );
      fake.emitAction(
        const AppAction(
          name: 'open_settings',
          payload: <String, Object>{'tab': 'billing'},
          experience: ExperienceRef(
            experienceId: 'experience-1',
            journeyId: 'journey-1',
          ),
        ),
      );

      expect((await activity).name, r'$journey_leg_started');
      expect((await action).experience.journeyId, 'journey-1');
    });

    test('purchase controller completes canonical results', () async {
      final controller = _PurchaseController();
      await Nuxie.initialize(
        apiKey: 'NX_TEST',
        purchaseController: controller,
        platformOverride: fake,
      );

      fake.emitPurchase(
        const NuxiePurchaseRequest(
          requestId: 'purchase-1',
          platform: 'android',
          productId: 'pro',
          storeProductId: 'pro:monthly',
          timestampMs: 1,
        ),
      );
      fake.emitRestore(
        const NuxieRestoreRequest(
          requestId: 'restore-1',
          platform: 'android',
          timestampMs: 2,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1));

      expect(fake.usingPurchaseController, isTrue);
      expect(
        fake.completedPurchases.single.result.type,
        NuxiePurchaseResultType.purchased,
      );
      expect(
        fake.completedRestores.single.result.type,
        NuxieRestoreResultType.noPurchases,
      );
    });
  });
}

class _FakePlatform extends NuxieFlutterPlatform {
  final _features = StreamController<FeatureAccessChangedEvent>.broadcast();
  final _activities = StreamController<NuxieActivityInfo>.broadcast();
  final _actions = StreamController<AppAction>.broadcast();
  final _purchases = StreamController<NuxiePurchaseRequest>.broadcast();
  final _restores = StreamController<NuxieRestoreRequest>.broadcast();

  String? apiKey;
  NuxieOptions? options;
  bool? usingPurchaseController;
  final List<_EventCall> events = <_EventCall>[];
  final List<bool> resetValues = <bool>[];
  final List<_CompletedPurchase> completedPurchases = <_CompletedPurchase>[];
  final List<_CompletedRestore> completedRestores = <_CompletedRestore>[];
  FeatureCheckPolicy? featurePolicy;
  double? requiredBalance;

  @override
  Stream<FeatureAccessChangedEvent> get featureAccessChanges =>
      _features.stream;
  @override
  Stream<NuxieActivityInfo> get activities => _activities.stream;
  @override
  Stream<AppAction> get appActions => _actions.stream;
  @override
  Stream<NuxiePurchaseRequest> get purchaseRequests => _purchases.stream;
  @override
  Stream<NuxieRestoreRequest> get restoreRequests => _restores.stream;

  @override
  Future<void> configure({
    required String apiKey,
    NuxieOptions? options,
    required bool usingPurchaseController,
    required String wrapperVersion,
  }) async {
    this.apiKey = apiKey;
    this.options = options;
    this.usingPurchaseController = usingPurchaseController;
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
  Future<void> reset({bool keepAnonymousId = false}) async {
    resetValues.add(keepAnonymousId);
  }

  @override
  Future<String> getDistinctId() async => 'distinct';
  @override
  Future<String> getAnonymousId() async => 'anonymous';
  @override
  Future<bool> getIsIdentified() async => true;

  @override
  void trigger(String event, {Map<String, Object?>? properties}) {
    events.add(_EventCall(event, properties));
  }

  @override
  Future<void> dismiss() async {}
  @override
  Future<void> setLocaleIdentifier(String? localeIdentifier) async {}

  @override
  Future<FeatureAccess> hasFeature(
    String featureId, {
    double requiredBalance = 1,
    String? entityId,
    FeatureCheckPolicy policy = FeatureCheckPolicy.cacheFirst,
  }) async {
    this.requiredBalance = requiredBalance;
    featurePolicy = policy;
    return const FeatureAccess(
      allowed: true,
      unlimited: false,
      balance: 3.5,
      type: FeatureType.metered,
    );
  }

  @override
  void useFeature(
    String featureId, {
    double amount = 1,
    String? entityId,
    Map<String, Object?>? metadata,
  }) {}

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
      featureId: 'credits',
      amountUsed: 1.5,
      authoritativeAccess: FeatureAccess(
        allowed: true,
        unlimited: false,
        balance: 8,
        type: FeatureType.creditSystem,
      ),
    );
  }

  @override
  void completePurchase(String requestId, NuxiePurchaseResult result) {
    completedPurchases.add(_CompletedPurchase(requestId, result));
  }

  @override
  void completeRestore(String requestId, NuxieRestoreResult result) {
    completedRestores.add(_CompletedRestore(requestId, result));
  }

  void emitActivity(NuxieActivityInfo value) => _activities.add(value);
  void emitAction(AppAction value) => _actions.add(value);
  void emitPurchase(NuxiePurchaseRequest value) => _purchases.add(value);
  void emitRestore(NuxieRestoreRequest value) => _restores.add(value);

  Future<void> dispose() async {
    await Future.wait(<Future<void>>[
      _features.close(),
      _activities.close(),
      _actions.close(),
      _purchases.close(),
      _restores.close(),
    ]);
  }
}

class _EventCall {
  const _EventCall(this.event, this.properties);
  final String event;
  final Map<String, Object?>? properties;
}

class _CompletedPurchase {
  const _CompletedPurchase(this.requestId, this.result);
  final String requestId;
  final NuxiePurchaseResult result;
}

class _CompletedRestore {
  const _CompletedRestore(this.requestId, this.result);
  final String requestId;
  final NuxieRestoreResult result;
}

class _PurchaseController implements NuxiePurchaseController {
  @override
  Future<NuxiePurchaseResult> purchase(NuxiePurchaseRequest request) async =>
      const NuxiePurchaseResult(type: NuxiePurchaseResultType.purchased);

  @override
  Future<NuxieRestoreResult> restore(NuxieRestoreRequest request) async =>
      const NuxieRestoreResult(type: NuxieRestoreResultType.noPurchases);
}
