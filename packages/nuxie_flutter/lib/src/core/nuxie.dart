import 'dart:async';

import 'package:nuxie_flutter_native/nuxie_flutter_native.dart';
import 'package:nuxie_flutter_platform_interface/nuxie_flutter_platform_interface.dart';

class Nuxie {
  Nuxie._({
    required this.platform,
    required String wrapperVersion,
    NuxiePurchaseController? purchaseController,
  })  : _sdkVersion = wrapperVersion,
        _purchaseController = purchaseController;

  static Nuxie? _instance;

  static Nuxie get instance {
    final value = _instance;
    if (value == null) {
      throw const NuxieException(
        code: 'NOT_CONFIGURED',
        message: 'Nuxie.initialize must be called before Nuxie.instance.',
      );
    }
    return value;
  }

  static Future<Nuxie> initialize({
    required String apiKey,
    NuxieOptions? options,
    NuxiePurchaseController? purchaseController,
    String wrapperVersion = '0.1.0',
    NuxieFlutterPlatform? platformOverride,
  }) async {
    final existing = _instance;
    if (existing != null && existing._isConfigured) {
      existing.setPurchaseController(purchaseController);
      return existing;
    }

    if (platformOverride != null) {
      NuxieFlutterPlatform.instance = platformOverride;
    } else {
      registerNuxieFlutterNative();
    }

    final platform = NuxieFlutterPlatform.instance;
    await platform.configure(
      apiKey: apiKey,
      options: options,
      usingPurchaseController: purchaseController != null,
      wrapperVersion: wrapperVersion,
    );

    final nuxie = Nuxie._(
      platform: platform,
      wrapperVersion: wrapperVersion,
      purchaseController: purchaseController,
    );
    nuxie._bindCommerce();
    _instance = nuxie;
    return nuxie;
  }

  final NuxieFlutterPlatform platform;
  final String _sdkVersion;

  NuxiePurchaseController? _purchaseController;
  StreamSubscription<NuxiePurchaseRequest>? _purchaseSubscription;
  StreamSubscription<NuxieRestoreRequest>? _restoreSubscription;
  bool _isConfigured = true;

  bool get isConfigured => _isConfigured;
  String get sdkVersion => _sdkVersion;

  Stream<FeatureAccessChangedEvent> get featureAccessChanges =>
      platform.featureAccessChanges;
  Stream<NuxieActivityInfo> get activities => platform.activities;
  Stream<AppAction> get appActions => platform.appActions;
  Stream<NuxiePurchaseRequest> get purchaseRequests =>
      platform.purchaseRequests;
  Stream<NuxieRestoreRequest> get restoreRequests => platform.restoreRequests;

  void setPurchaseController(NuxiePurchaseController? controller) {
    _purchaseController = controller;
  }

  Future<void> identify(
    String distinctId, {
    Map<String, Object?>? userProperties,
    Map<String, Object?>? userPropertiesSetOnce,
  }) {
    _assertConfigured();
    return platform.identify(
      distinctId,
      userProperties: userProperties,
      userPropertiesSetOnce: userPropertiesSetOnce,
    );
  }

  Future<void> reset({bool keepAnonymousId = false}) {
    _assertConfigured();
    return platform.reset(keepAnonymousId: keepAnonymousId);
  }

  Future<String> getDistinctId() {
    _assertConfigured();
    return platform.getDistinctId();
  }

  Future<String> getAnonymousId() {
    _assertConfigured();
    return platform.getAnonymousId();
  }

  Future<bool> getIsIdentified() {
    _assertConfigured();
    return platform.getIsIdentified();
  }

  /// Captures one event. Matching Journeys continue asynchronously in native code.
  void trigger(String event, {Map<String, Object?>? properties}) {
    _assertConfigured();
    platform.trigger(event, properties: properties);
  }

  Future<void> dismiss() {
    _assertConfigured();
    return platform.dismiss();
  }

  Future<void> setLocaleIdentifier(String? localeIdentifier) {
    _assertConfigured();
    return platform.setLocaleIdentifier(localeIdentifier);
  }

  Future<FeatureAccess> hasFeature(
    String featureId, {
    double requiredBalance = 1,
    String? entityId,
    FeatureCheckPolicy policy = FeatureCheckPolicy.cacheFirst,
  }) {
    _assertConfigured();
    return platform.hasFeature(
      featureId,
      requiredBalance: requiredBalance,
      entityId: entityId,
      policy: policy,
    );
  }

  void useFeature(
    String featureId, {
    double amount = 1,
    String? entityId,
    Map<String, Object?>? metadata,
  }) {
    _assertConfigured();
    platform.useFeature(
      featureId,
      amount: amount,
      entityId: entityId,
      metadata: metadata,
    );
  }

  Future<FeatureUsageResult> useFeatureAndWait(
    String featureId, {
    double amount = 1,
    String? entityId,
    bool setUsage = false,
    Map<String, Object?>? metadata,
  }) {
    _assertConfigured();
    return platform.useFeatureAndWait(
      featureId,
      amount: amount,
      entityId: entityId,
      setUsage: setUsage,
      metadata: metadata,
    );
  }

  Future<void> shutdown() async {
    if (!_isConfigured) {
      return;
    }
    await _purchaseSubscription?.cancel();
    await _restoreSubscription?.cancel();
    _purchaseSubscription = null;
    _restoreSubscription = null;
    await platform.shutdown();
    _isConfigured = false;
    if (identical(_instance, this)) {
      _instance = null;
    }
  }

  void _bindCommerce() {
    _purchaseSubscription = platform.purchaseRequests.listen((request) {
      unawaited(_handlePurchase(request));
    });
    _restoreSubscription = platform.restoreRequests.listen((request) {
      unawaited(_handleRestore(request));
    });
  }

  Future<void> _handlePurchase(NuxiePurchaseRequest request) async {
    final controller = _purchaseController;
    if (controller == null) {
      platform.completePurchase(
        request.requestId,
        const NuxiePurchaseResult(
          type: NuxiePurchaseResultType.failed,
          message: 'purchase_controller_unavailable',
        ),
      );
      return;
    }
    try {
      platform.completePurchase(
        request.requestId,
        await controller.purchase(request),
      );
    } catch (error) {
      platform.completePurchase(
        request.requestId,
        NuxiePurchaseResult(
          type: NuxiePurchaseResultType.failed,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> _handleRestore(NuxieRestoreRequest request) async {
    final controller = _purchaseController;
    if (controller == null) {
      platform.completeRestore(
        request.requestId,
        const NuxieRestoreResult(
          type: NuxieRestoreResultType.failed,
          message: 'purchase_controller_unavailable',
        ),
      );
      return;
    }
    try {
      platform.completeRestore(
        request.requestId,
        await controller.restore(request),
      );
    } catch (error) {
      platform.completeRestore(
        request.requestId,
        NuxieRestoreResult(
          type: NuxieRestoreResultType.failed,
          message: error.toString(),
        ),
      );
    }
  }

  void _assertConfigured() {
    if (!_isConfigured) {
      throw const NuxieException(
        code: 'NOT_CONFIGURED',
        message: 'Nuxie is not configured.',
      );
    }
  }
}
