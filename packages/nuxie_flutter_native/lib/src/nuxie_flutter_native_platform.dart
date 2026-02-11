import 'dart:async';

import 'package:nuxie_flutter_platform_interface/nuxie_flutter_platform_interface.dart';

import 'bridge_mappers.dart';
import 'generated/nuxie_bridge.g.dart';

class NuxieFlutterNativePlatform {
  static void registerWith() {
    NuxieFlutterPlatform.instance = NuxieFlutterNativePlatformImpl();
  }
}

class NuxieFlutterNativePlatformImpl extends NuxieFlutterPlatform {
  NuxieFlutterNativePlatformImpl({
    PNuxieHostApi? hostApi,
  })  : _hostApi = hostApi ?? PNuxieHostApi(),
        super() {
    PNuxieFlutterApi.setUp(_callbacks);
  }

  final PNuxieHostApi _hostApi;

  final StreamController<FeatureAccessChangedEvent>
      _featureAccessChangesController =
      StreamController<FeatureAccessChangedEvent>.broadcast();
  final StreamController<NuxieFlowLifecycleEvent> _flowLifecycleController =
      StreamController<NuxieFlowLifecycleEvent>.broadcast();
  final StreamController<NuxieLogEvent> _logController =
      StreamController<NuxieLogEvent>.broadcast();
  final StreamController<NuxieTriggerUpdateEvent> _triggerUpdatesController =
      StreamController<NuxieTriggerUpdateEvent>.broadcast();
  final StreamController<NuxiePurchaseRequest> _purchaseRequestsController =
      StreamController<NuxiePurchaseRequest>.broadcast();
  final StreamController<NuxieRestoreRequest> _restoreRequestsController =
      StreamController<NuxieRestoreRequest>.broadcast();

  late final _NuxieFlutterCallbacks _callbacks = _NuxieFlutterCallbacks(
    onFeatureAccessChanged: _featureAccessChangesController.add,
    onFlowLifecycle: _flowLifecycleController.add,
    onLog: _logController.add,
    onPurchaseRequest: _purchaseRequestsController.add,
    onRestoreRequest: _restoreRequestsController.add,
    onTriggerUpdate: _triggerUpdatesController.add,
  );

  @override
  Stream<FeatureAccessChangedEvent> get featureAccessChanges =>
      _featureAccessChangesController.stream;

  @override
  Stream<NuxieFlowLifecycleEvent> get flowLifecycleEvents =>
      _flowLifecycleController.stream;

  @override
  Stream<NuxieLogEvent> get logEvents => _logController.stream;

  @override
  Stream<NuxieTriggerUpdateEvent> get triggerUpdates =>
      _triggerUpdatesController.stream;

  @override
  Stream<NuxiePurchaseRequest> get purchaseRequests =>
      _purchaseRequestsController.stream;

  @override
  Stream<NuxieRestoreRequest> get restoreRequests =>
      _restoreRequestsController.stream;

  @override
  Future<void> configure({
    required String apiKey,
    NuxieOptions? options,
    required bool usingPurchaseController,
    required String wrapperVersion,
  }) {
    final resolved = options ?? const NuxieOptions();
    return _hostApi.configure(
      toConfigureRequest(
        apiKey: apiKey,
        wrapperVersion: wrapperVersion,
        usingPurchaseController: usingPurchaseController,
        options: resolved,
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
  Future<void> reset({bool keepAnonymousId = true}) {
    return _hostApi.reset(keepAnonymousId);
  }

  @override
  Future<String> getDistinctId() => _hostApi.getDistinctId();

  @override
  Future<String> getAnonymousId() => _hostApi.getAnonymousId();

  @override
  Future<bool> getIsIdentified() => _hostApi.getIsIdentified();

  @override
  Future<void> startTrigger(
    String requestId, {
    required String event,
    Map<String, Object?>? properties,
    Map<String, Object?>? userProperties,
    Map<String, Object?>? userPropertiesSetOnce,
  }) {
    return _hostApi.startTrigger(
      toTriggerRequest(
        requestId,
        event: event,
        properties: properties,
        userProperties: userProperties,
        userPropertiesSetOnce: userPropertiesSetOnce,
      ),
    );
  }

  @override
  Future<void> cancelTrigger(String requestId) {
    return _hostApi.cancelTrigger(requestId);
  }

  @override
  Future<void> showFlow(String flowId) => _hostApi.showFlow(flowId);

  @override
  Future<ProfileResponse> refreshProfile() async {
    final response = await _hostApi.refreshProfile();
    return fromProfileResponse(response);
  }

  @override
  Future<FeatureAccess> hasFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  }) async {
    final access =
        await _hostApi.hasFeature(featureId, requiredBalance, entityId);
    return fromFeatureAccess(access);
  }

  @override
  Future<FeatureAccess?> getCachedFeature(
    String featureId, {
    String? entityId,
  }) async {
    final access = await _hostApi.getCachedFeature(featureId, entityId);
    if (access == null) {
      return null;
    }
    return fromFeatureAccess(access);
  }

  @override
  Future<FeatureCheckResult> checkFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  }) async {
    final result = await _hostApi.checkFeature(
      featureId,
      requiredBalance,
      entityId,
    );
    return fromFeatureCheckResult(result);
  }

  @override
  Future<FeatureCheckResult> refreshFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  }) async {
    final result = await _hostApi.refreshFeature(
      featureId,
      requiredBalance,
      entityId,
    );
    return fromFeatureCheckResult(result);
  }

  @override
  Future<void> useFeature(
    String featureId, {
    double amount = 1,
    String? entityId,
    Map<String, Object?>? metadata,
  }) {
    return _hostApi.useFeature(
      featureId,
      amount,
      entityId,
      metadata,
    );
  }

  @override
  Future<FeatureUsageResult> useFeatureAndWait(
    String featureId, {
    double amount = 1,
    String? entityId,
    bool setUsage = false,
    Map<String, Object?>? metadata,
  }) async {
    final result = await _hostApi.useFeatureAndWait(
      featureId,
      amount,
      entityId,
      setUsage,
      metadata,
    );
    return fromFeatureUsageResult(result);
  }

  @override
  Future<bool> flushEvents() => _hostApi.flushEvents();

  @override
  Future<int> getQueuedEventCount() => _hostApi.getQueuedEventCount();

  @override
  Future<void> pauseEventQueue() => _hostApi.pauseEventQueue();

  @override
  Future<void> resumeEventQueue() => _hostApi.resumeEventQueue();

  @override
  Future<void> completePurchase(String requestId, NuxiePurchaseResult result) {
    return _hostApi.completePurchase(requestId, toPurchaseResult(result));
  }

  @override
  Future<void> completeRestore(String requestId, NuxieRestoreResult result) {
    return _hostApi.completeRestore(requestId, toRestoreResult(result));
  }
}

class _NuxieFlutterCallbacks extends PNuxieFlutterApi {
  _NuxieFlutterCallbacks({
    required void Function(FeatureAccessChangedEvent event)
        onFeatureAccessChanged,
    required void Function(NuxieFlowLifecycleEvent event) onFlowLifecycle,
    required void Function(NuxieLogEvent event) onLog,
    required void Function(NuxiePurchaseRequest request) onPurchaseRequest,
    required void Function(NuxieRestoreRequest request) onRestoreRequest,
    required void Function(NuxieTriggerUpdateEvent event) onTriggerUpdate,
  })  : _onFeatureAccessChanged = onFeatureAccessChanged,
        _onFlowLifecycle = onFlowLifecycle,
        _onLog = onLog,
        _onPurchaseRequest = onPurchaseRequest,
        _onRestoreRequest = onRestoreRequest,
        _onTriggerUpdate = onTriggerUpdate;

  final void Function(FeatureAccessChangedEvent event) _onFeatureAccessChanged;
  final void Function(NuxieFlowLifecycleEvent event) _onFlowLifecycle;
  final void Function(NuxieLogEvent event) _onLog;
  final void Function(NuxiePurchaseRequest request) _onPurchaseRequest;
  final void Function(NuxieRestoreRequest request) _onRestoreRequest;
  final void Function(NuxieTriggerUpdateEvent event) _onTriggerUpdate;

  @override
  void onFeatureAccessChanged(PFeatureAccessChangedEvent event) {
    _onFeatureAccessChanged(fromFeatureAccessChangedEvent(event));
  }

  @override
  void onFlowLifecycle(PFlowLifecycleEvent event) {
    _onFlowLifecycle(fromFlowLifecycleEvent(event));
  }

  @override
  void onLog(PLogEvent event) {
    _onLog(fromLogEvent(event));
  }

  @override
  void onPurchaseRequest(PPurchaseRequest request) {
    _onPurchaseRequest(fromPurchaseRequest(request));
  }

  @override
  void onRestoreRequest(PRestoreRequest request) {
    _onRestoreRequest(fromRestoreRequest(request));
  }

  @override
  void onTriggerUpdate(PTriggerUpdate event) {
    _onTriggerUpdate(fromTriggerUpdate(event));
  }
}
