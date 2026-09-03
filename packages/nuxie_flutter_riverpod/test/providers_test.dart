import 'package:flutter_test/flutter_test.dart';
import 'package:nuxie_flutter/nuxie_flutter.dart';
import 'package:nuxie_flutter_riverpod/nuxie_flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  test('Feature provider forwards policy and fractional balance', () async {
    final platform = _FeaturePlatform();
    final nuxie = await Nuxie.initialize(
      apiKey: 'NX_TEST',
      platformOverride: platform,
    );
    final container = ProviderContainer(
      overrides: <Override>[nuxieProvider.overrideWithValue(nuxie)],
    );

    final value = await container.read(
      nuxieFeatureProvider(
        const NuxieFeatureQuery(
          'credits',
          requiredBalance: 2.5,
          policy: FeatureCheckPolicy.remote,
        ),
      ).future,
    );

    expect(value?.balance, 3.5);
    expect(platform.policy, FeatureCheckPolicy.remote);
    expect(platform.requiredBalance, 2.5);

    container.dispose();
    await nuxie.shutdown();
  });
}

class _FeaturePlatform extends NuxieFlutterPlatform {
  FeatureCheckPolicy? policy;
  double? requiredBalance;

  @override
  Stream<FeatureAccessChangedEvent> get featureAccessChanges =>
      const Stream<FeatureAccessChangedEvent>.empty();
  @override
  Stream<NuxieActivityInfo> get activities =>
      const Stream<NuxieActivityInfo>.empty();
  @override
  Stream<AppAction> get appActions => const Stream<AppAction>.empty();
  @override
  Stream<NuxiePurchaseRequest> get purchaseRequests =>
      const Stream<NuxiePurchaseRequest>.empty();
  @override
  Stream<NuxieRestoreRequest> get restoreRequests =>
      const Stream<NuxieRestoreRequest>.empty();

  @override
  Future<void> configure(
      {required String apiKey,
      NuxieOptions? options,
      required bool usingPurchaseController,
      required String wrapperVersion}) async {}
  @override
  Future<void> shutdown() async {}
  @override
  Future<void> identify(String distinctId,
      {Map<String, Object?>? userProperties,
      Map<String, Object?>? userPropertiesSetOnce}) async {}
  @override
  Future<void> reset({bool keepAnonymousId = false}) async {}
  @override
  Future<String> getDistinctId() async => 'distinct';
  @override
  Future<String> getAnonymousId() async => 'anonymous';
  @override
  Future<bool> getIsIdentified() async => true;
  @override
  void trigger(String event, {Map<String, Object?>? properties}) {}
  @override
  Future<void> dismiss() async {}
  @override
  Future<void> setLocaleIdentifier(String? localeIdentifier) async {}

  @override
  Future<FeatureAccess> hasFeature(String featureId,
      {double requiredBalance = 1,
      String? entityId,
      FeatureCheckPolicy policy = FeatureCheckPolicy.cacheFirst}) async {
    this.requiredBalance = requiredBalance;
    this.policy = policy;
    return const FeatureAccess(
      allowed: true,
      unlimited: false,
      balance: 3.5,
      type: FeatureType.metered,
    );
  }

  @override
  void useFeature(String featureId,
      {double amount = 1, String? entityId, Map<String, Object?>? metadata}) {}
  @override
  Future<FeatureUsageResult> useFeatureAndWait(String featureId,
          {double amount = 1,
          String? entityId,
          bool setUsage = false,
          Map<String, Object?>? metadata}) async =>
      const FeatureUsageResult(
        success: true,
        featureId: 'credits',
        amountUsed: 1,
      );
  @override
  void completePurchase(String requestId, NuxiePurchaseResult result) {}
  @override
  void completeRestore(String requestId, NuxieRestoreResult result) {}
}
