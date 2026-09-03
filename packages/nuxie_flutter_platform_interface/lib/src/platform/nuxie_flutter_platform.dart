import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../events/nuxie_events.dart';
import '../models/feature_models.dart';
import '../models/journey_models.dart';
import '../models/nuxie_options.dart';
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
  Stream<NuxieActivityInfo> get activities;
  Stream<AppAction> get appActions;
  Stream<NuxiePurchaseRequest> get purchaseRequests;
  Stream<NuxieRestoreRequest> get restoreRequests;

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

  Future<void> reset({bool keepAnonymousId = false});
  Future<String> getDistinctId();
  Future<String> getAnonymousId();
  Future<bool> getIsIdentified();

  void trigger(String event, {Map<String, Object?>? properties});

  Future<void> dismiss();
  Future<void> setLocaleIdentifier(String? localeIdentifier);

  Future<FeatureAccess> hasFeature(
    String featureId, {
    double requiredBalance = 1,
    String? entityId,
    FeatureCheckPolicy policy = FeatureCheckPolicy.cacheFirst,
  });

  void useFeature(
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

  void completePurchase(String requestId, NuxiePurchaseResult result);
  void completeRestore(String requestId, NuxieRestoreResult result);
}

class _UnsupportedNuxieFlutterPlatform extends NuxieFlutterPlatform {
  Never _unsupported() => throw UnimplementedError(
        'No nuxie_flutter platform implementation has been registered.',
      );

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
  Future<void> configure({
    required String apiKey,
    NuxieOptions? options,
    required bool usingPurchaseController,
    required String wrapperVersion,
  }) async =>
      _unsupported();

  @override
  Future<void> shutdown() async => _unsupported();

  @override
  Future<void> identify(
    String distinctId, {
    Map<String, Object?>? userProperties,
    Map<String, Object?>? userPropertiesSetOnce,
  }) async =>
      _unsupported();

  @override
  Future<void> reset({bool keepAnonymousId = false}) async => _unsupported();

  @override
  Future<String> getDistinctId() async => _unsupported();

  @override
  Future<String> getAnonymousId() async => _unsupported();

  @override
  Future<bool> getIsIdentified() async => _unsupported();

  @override
  void trigger(String event, {Map<String, Object?>? properties}) =>
      _unsupported();

  @override
  Future<void> dismiss() async => _unsupported();

  @override
  Future<void> setLocaleIdentifier(String? localeIdentifier) async =>
      _unsupported();

  @override
  Future<FeatureAccess> hasFeature(
    String featureId, {
    double requiredBalance = 1,
    String? entityId,
    FeatureCheckPolicy policy = FeatureCheckPolicy.cacheFirst,
  }) async =>
      _unsupported();

  @override
  void useFeature(
    String featureId, {
    double amount = 1,
    String? entityId,
    Map<String, Object?>? metadata,
  }) =>
      _unsupported();

  @override
  Future<FeatureUsageResult> useFeatureAndWait(
    String featureId, {
    double amount = 1,
    String? entityId,
    bool setUsage = false,
    Map<String, Object?>? metadata,
  }) async =>
      _unsupported();

  @override
  void completePurchase(String requestId, NuxiePurchaseResult result) =>
      _unsupported();

  @override
  void completeRestore(String requestId, NuxieRestoreResult result) =>
      _unsupported();
}
