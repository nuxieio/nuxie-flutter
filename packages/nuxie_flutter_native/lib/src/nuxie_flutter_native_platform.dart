import 'dart:async';

import 'package:nuxie_flutter_platform_interface/nuxie_flutter_platform_interface.dart';

import 'bridge_mappers.dart';
import 'generated/nuxie_bridge.g.dart';

void registerNuxieFlutterNative() {
  NuxieFlutterNativePlatform.registerWith();
}

class NuxieFlutterNativePlatform {
  static void registerWith() {
    NuxieFlutterPlatform.instance = NuxieFlutterNativePlatformImpl();
  }
}

class NuxieFlutterNativePlatformImpl extends NuxieFlutterPlatform {
  NuxieFlutterNativePlatformImpl({PNuxieHostApi? hostApi})
      : _hostApi = hostApi ?? PNuxieHostApi(),
        super() {
    PNuxieFlutterApi.setUp(_callbacks);
  }

  final PNuxieHostApi _hostApi;
  final StreamController<FeatureAccessChangedEvent> _featureChanges =
      StreamController<FeatureAccessChangedEvent>.broadcast();
  final StreamController<NuxieActivityInfo> _activities =
      StreamController<NuxieActivityInfo>.broadcast();
  final StreamController<AppAction> _appActions =
      StreamController<AppAction>.broadcast();
  final StreamController<NuxiePurchaseRequest> _purchases =
      StreamController<NuxiePurchaseRequest>.broadcast();
  final StreamController<NuxieRestoreRequest> _restores =
      StreamController<NuxieRestoreRequest>.broadcast();

  late final _NuxieFlutterCallbacks _callbacks = _NuxieFlutterCallbacks(
    onFeatureAccessChangedCallback: _featureChanges.add,
    onActivityCallback: _activities.add,
    onAppActionCallback: _appActions.add,
    onPurchaseRequestCallback: _purchases.add,
    onRestoreRequestCallback: _restores.add,
  );

  @override
  Stream<FeatureAccessChangedEvent> get featureAccessChanges =>
      _featureChanges.stream;

  @override
  Stream<NuxieActivityInfo> get activities => _activities.stream;

  @override
  Stream<AppAction> get appActions => _appActions.stream;

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
  }) {
    return _hostApi.configure(
      toConfigureRequest(
        apiKey: apiKey,
        wrapperVersion: wrapperVersion,
        usingPurchaseController: usingPurchaseController,
        options: options ?? const NuxieOptions(),
      ),
    );
  }

  @override
  Future<void> shutdown() => _hostApi.shutdown();

  @override
  Future<void> identify(
    String distinctId, {
    Map<String, Object?>? userProperties,
    Map<String, Object?>? userPropertiesSetOnce,
  }) {
    return _hostApi.identify(
      distinctId,
      userProperties,
      userPropertiesSetOnce,
    );
  }

  @override
  Future<void> reset({bool keepAnonymousId = false}) =>
      _hostApi.reset(keepAnonymousId);

  @override
  Future<String> getDistinctId() => _hostApi.getDistinctId();

  @override
  Future<String> getAnonymousId() => _hostApi.getAnonymousId();

  @override
  Future<bool> getIsIdentified() => _hostApi.getIsIdentified();

  @override
  void trigger(String event, {Map<String, Object?>? properties}) {
    unawaited(_hostApi.trigger(event, properties));
  }

  @override
  Future<void> dismiss() => _hostApi.dismiss();

  @override
  Future<void> setLocaleIdentifier(String? localeIdentifier) =>
      _hostApi.setLocaleIdentifier(localeIdentifier);

  @override
  Future<FeatureAccess> hasFeature(
    String featureId, {
    double requiredBalance = 1,
    String? entityId,
    FeatureCheckPolicy policy = FeatureCheckPolicy.cacheFirst,
  }) async {
    return fromFeatureAccess(
      await _hostApi.hasFeature(
        featureId,
        requiredBalance,
        entityId,
        policy.name,
      ),
    );
  }

  @override
  void useFeature(
    String featureId, {
    double amount = 1,
    String? entityId,
    Map<String, Object?>? metadata,
  }) {
    unawaited(_hostApi.useFeature(featureId, amount, entityId, metadata));
  }

  @override
  Future<FeatureUsageResult> useFeatureAndWait(
    String featureId, {
    double amount = 1,
    String? entityId,
    bool setUsage = false,
    Map<String, Object?>? metadata,
  }) async {
    return fromFeatureUsageResult(
      await _hostApi.useFeatureAndWait(
        featureId,
        amount,
        entityId,
        setUsage,
        metadata,
      ),
    );
  }

  @override
  void completePurchase(String requestId, NuxiePurchaseResult result) {
    unawaited(_hostApi.completePurchase(requestId, toPurchaseResult(result)));
  }

  @override
  void completeRestore(String requestId, NuxieRestoreResult result) {
    unawaited(_hostApi.completeRestore(requestId, toRestoreResult(result)));
  }
}

class _NuxieFlutterCallbacks extends PNuxieFlutterApi {
  _NuxieFlutterCallbacks({
    required this.onFeatureAccessChangedCallback,
    required this.onActivityCallback,
    required this.onAppActionCallback,
    required this.onPurchaseRequestCallback,
    required this.onRestoreRequestCallback,
  });

  final void Function(FeatureAccessChangedEvent) onFeatureAccessChangedCallback;
  final void Function(NuxieActivityInfo) onActivityCallback;
  final void Function(AppAction) onAppActionCallback;
  final void Function(NuxiePurchaseRequest) onPurchaseRequestCallback;
  final void Function(NuxieRestoreRequest) onRestoreRequestCallback;

  @override
  void onFeatureAccessChanged(PFeatureAccessChangedEvent event) {
    onFeatureAccessChangedCallback(fromFeatureAccessChangedEvent(event));
  }

  @override
  void onActivity(PActivityInfo activity) {
    onActivityCallback(fromActivityInfo(activity));
  }

  @override
  void onAppAction(PAppAction action) {
    onAppActionCallback(fromAppAction(action));
  }

  @override
  void onPurchaseRequest(PPurchaseRequest request) {
    onPurchaseRequestCallback(fromPurchaseRequest(request));
  }

  @override
  void onRestoreRequest(PRestoreRequest request) {
    onRestoreRequestCallback(fromRestoreRequest(request));
  }
}
