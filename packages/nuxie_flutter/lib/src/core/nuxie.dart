import 'dart:async';

import 'package:nuxie_flutter_native/nuxie_flutter_native.dart';
import 'package:nuxie_flutter_platform_interface/nuxie_flutter_platform_interface.dart';

class Nuxie {
  Nuxie._({
    required this.platform,
    required String wrapperVersion,
  }) : _sdkVersion = wrapperVersion;

  static Nuxie? _instance;
  static int _requestCounter = 0;

  static Nuxie get instance {
    final instance = _instance;
    if (instance == null) {
      throw const NuxieException(
        code: 'NOT_CONFIGURED',
        message: 'Nuxie.initialize must be called before Nuxie.instance.',
      );
    }
    return instance;
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
      if (purchaseController != null) {
        existing.setPurchaseController(purchaseController);
      }
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
    ).._purchaseController = purchaseController;

    nuxie._bindPlatformStreams();
    _instance = nuxie;
    return nuxie;
  }

  final NuxieFlutterPlatform platform;

  final String _sdkVersion;

  NuxiePurchaseController? _purchaseController;

  StreamSubscription<NuxieTriggerUpdateEvent>? _triggerUpdatesSubscription;
  StreamSubscription<NuxiePurchaseRequest>? _purchaseRequestsSubscription;
  StreamSubscription<NuxieRestoreRequest>? _restoreRequestsSubscription;

  final Map<String, _TriggerOperationState> _triggerOperations =
      <String, _TriggerOperationState>{};

  bool _isConfigured = true;

  bool get isConfigured => _isConfigured;

  String get sdkVersion => _sdkVersion;

  NuxiePurchaseController? get purchaseController => _purchaseController;

  Stream<FeatureAccessChangedEvent> get featureAccessChanges =>
      platform.featureAccessChanges;

  Stream<NuxieFlowLifecycleEvent> get flowLifecycleEvents =>
      platform.flowLifecycleEvents;

  Stream<NuxieLogEvent> get logEvents => platform.logEvents;

  Stream<NuxieTriggerUpdateEvent> get triggerUpdates => platform.triggerUpdates;

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

  Future<void> reset({bool keepAnonymousId = true}) {
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

  NuxieTriggerOperation trigger(
    String event, {
    Map<String, Object?>? properties,
    Map<String, Object?>? userProperties,
    Map<String, Object?>? userPropertiesSetOnce,
  }) {
    _assertConfigured();

    final requestId = _nextRequestId();
    final state = _TriggerOperationState();
    _triggerOperations[requestId] = state;

    unawaited(
      _startTrigger(
        requestId,
        event: event,
        properties: properties,
        userProperties: userProperties,
        userPropertiesSetOnce: userPropertiesSetOnce,
      ),
    );

    return NuxieTriggerOperation(
      requestId: requestId,
      updates: state.updates,
      done: state.done,
      onCancel: () => _cancelTrigger(requestId),
    );
  }

  Future<TriggerTerminalUpdate> triggerOnce(
    String event, {
    Map<String, Object?>? properties,
    Map<String, Object?>? userProperties,
    Map<String, Object?>? userPropertiesSetOnce,
    Duration? timeout,
  }) async {
    final operation = trigger(
      event,
      properties: properties,
      userProperties: userProperties,
      userPropertiesSetOnce: userPropertiesSetOnce,
    );

    if (timeout == null) {
      return operation.done;
    }

    try {
      return await operation.done.timeout(timeout);
    } on TimeoutException {
      await operation.cancel();
      return const TriggerErrorUpdate(
        TriggerError(
          code: 'trigger_timeout',
          message: 'Trigger operation timed out.',
        ),
      );
    }
  }

  Future<void> showFlow(String flowId) {
    _assertConfigured();
    return platform.showFlow(flowId);
  }

  Future<ProfileResponse> refreshProfile() {
    _assertConfigured();
    return platform.refreshProfile();
  }

  Future<FeatureAccess> hasFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  }) {
    _assertConfigured();
    return platform.hasFeature(
      featureId,
      requiredBalance: requiredBalance,
      entityId: entityId,
    );
  }

  Future<FeatureAccess?> getCachedFeature(
    String featureId, {
    String? entityId,
  }) {
    _assertConfigured();
    return platform.getCachedFeature(
      featureId,
      entityId: entityId,
    );
  }

  Future<FeatureCheckResult> checkFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  }) {
    _assertConfigured();
    return platform.checkFeature(
      featureId,
      requiredBalance: requiredBalance,
      entityId: entityId,
    );
  }

  Future<FeatureCheckResult> refreshFeature(
    String featureId, {
    int? requiredBalance,
    String? entityId,
  }) {
    _assertConfigured();
    return platform.refreshFeature(
      featureId,
      requiredBalance: requiredBalance,
      entityId: entityId,
    );
  }

  Future<void> useFeature(
    String featureId, {
    double amount = 1,
    String? entityId,
    Map<String, Object?>? metadata,
  }) {
    _assertConfigured();
    return platform.useFeature(
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

  Future<bool> flushEvents() {
    _assertConfigured();
    return platform.flushEvents();
  }

  Future<int> getQueuedEventCount() {
    _assertConfigured();
    return platform.getQueuedEventCount();
  }

  Future<void> pauseEventQueue() {
    _assertConfigured();
    return platform.pauseEventQueue();
  }

  Future<void> resumeEventQueue() {
    _assertConfigured();
    return platform.resumeEventQueue();
  }

  Future<void> shutdown() async {
    if (!_isConfigured) {
      return;
    }

    await _triggerUpdatesSubscription?.cancel();
    await _purchaseRequestsSubscription?.cancel();
    await _restoreRequestsSubscription?.cancel();

    _triggerUpdatesSubscription = null;
    _purchaseRequestsSubscription = null;
    _restoreRequestsSubscription = null;

    for (final entry in _triggerOperations.entries.toList()) {
      _finishTrigger(
        entry.key,
        entry.value,
        const TriggerErrorUpdate(
          TriggerError(
            code: 'trigger_cancelled',
            message: 'Trigger cancelled during shutdown.',
          ),
        ),
      );
    }
    _triggerOperations.clear();

    await platform.shutdown();
    _isConfigured = false;
    if (identical(_instance, this)) {
      _instance = null;
    }
  }

  void _bindPlatformStreams() {
    _triggerUpdatesSubscription =
        platform.triggerUpdates.listen(_handleTriggerUpdate);
    _purchaseRequestsSubscription =
        platform.purchaseRequests.listen(_handlePurchaseRequest);
    _restoreRequestsSubscription =
        platform.restoreRequests.listen(_handleRestoreRequest);
  }

  Future<void> _startTrigger(
    String requestId, {
    required String event,
    Map<String, Object?>? properties,
    Map<String, Object?>? userProperties,
    Map<String, Object?>? userPropertiesSetOnce,
  }) async {
    try {
      await platform.startTrigger(
        requestId,
        event: event,
        properties: properties,
        userProperties: userProperties,
        userPropertiesSetOnce: userPropertiesSetOnce,
      );
    } catch (error) {
      final state = _triggerOperations[requestId];
      if (state == null || state.finished) {
        return;
      }
      _finishTrigger(
        requestId,
        state,
        TriggerErrorUpdate(
          TriggerError(
            code: 'trigger_start_failed',
            message: _errorMessage(error),
          ),
        ),
      );
    }
  }

  Future<void> _cancelTrigger(String requestId) async {
    final state = _triggerOperations[requestId];
    if (state == null || state.finished) {
      return;
    }

    try {
      await platform.cancelTrigger(requestId);
    } catch (_) {
      // Prefer deterministic local cancel behavior even if native cancel fails.
    }

    _finishTrigger(
      requestId,
      state,
      const TriggerErrorUpdate(
        TriggerError(
          code: 'trigger_cancelled',
          message: 'Trigger cancelled.',
        ),
      ),
    );
  }

  void _handleTriggerUpdate(NuxieTriggerUpdateEvent event) {
    final state = _triggerOperations[event.requestId];
    if (state == null || state.finished) {
      return;
    }

    state.add(event.update);

    final terminal = event.isTerminal || event.update.isTerminal;
    if (!terminal) {
      return;
    }

    final terminalUpdate = event.update.isTerminal
        ? event.update
        : const TriggerErrorUpdate(
            TriggerError(
              code: 'invalid_terminal_update',
              message:
                  'Native bridge marked a non-terminal trigger update terminal.',
            ),
          );
    _finishTrigger(event.requestId, state, terminalUpdate);
  }

  Future<void> _handlePurchaseRequest(NuxiePurchaseRequest request) async {
    final controller = _purchaseController;
    if (controller == null) {
      await _completePurchaseWithFailure(
        request.requestId,
        'purchase_controller_not_set',
      );
      return;
    }

    try {
      final result = await controller.onPurchase(request);
      await platform.completePurchase(request.requestId, result);
    } catch (error) {
      await _completePurchaseWithFailure(
        request.requestId,
        _errorMessage(error),
      );
    }
  }

  Future<void> _handleRestoreRequest(NuxieRestoreRequest request) async {
    final controller = _purchaseController;
    if (controller == null) {
      await _completeRestoreWithFailure(
        request.requestId,
        'restore_controller_not_set',
      );
      return;
    }

    try {
      final result = await controller.onRestore(request);
      await platform.completeRestore(request.requestId, result);
    } catch (error) {
      await _completeRestoreWithFailure(
        request.requestId,
        _errorMessage(error),
      );
    }
  }

  Future<void> _completePurchaseWithFailure(
    String requestId,
    String message,
  ) async {
    try {
      await platform.completePurchase(
        requestId,
        NuxiePurchaseResult(
          type: NuxiePurchaseResultType.failed,
          message: message,
        ),
      );
    } catch (_) {
      // Ignore follow-up completion failures.
    }
  }

  Future<void> _completeRestoreWithFailure(
    String requestId,
    String message,
  ) async {
    try {
      await platform.completeRestore(
        requestId,
        NuxieRestoreResult(
          type: NuxieRestoreResultType.failed,
          message: message,
        ),
      );
    } catch (_) {
      // Ignore follow-up completion failures.
    }
  }

  void _finishTrigger(
    String requestId,
    _TriggerOperationState state,
    TriggerTerminalUpdate update,
  ) {
    if (state.finished) {
      return;
    }

    state.finished = true;
    state.complete(update);
    _triggerOperations.remove(requestId);
  }

  void _assertConfigured() {
    if (!_isConfigured) {
      throw const NuxieException(
        code: 'NOT_CONFIGURED',
        message: 'Nuxie has not been configured. Call Nuxie.initialize first.',
      );
    }
  }

  String _nextRequestId() {
    _requestCounter += 1;
    return 'trigger-${DateTime.now().microsecondsSinceEpoch}-$_requestCounter';
  }

  static String _errorMessage(Object error) {
    if (error is NuxieException) {
      return error.message;
    }
    if (error is Exception) {
      return error.toString();
    }
    return '$error';
  }
}

abstract class NuxiePurchaseController {
  Future<NuxiePurchaseResult> onPurchase(NuxiePurchaseRequest request);

  Future<NuxieRestoreResult> onRestore(NuxieRestoreRequest request);
}

class NuxieTriggerOperation {
  NuxieTriggerOperation({
    required this.requestId,
    required this.updates,
    required this.done,
    required Future<void> Function() onCancel,
  }) : _onCancel = onCancel;

  final String requestId;
  final Stream<TriggerUpdate> updates;
  final Future<TriggerTerminalUpdate> done;
  final Future<void> Function() _onCancel;

  Future<void> cancel() => _onCancel();
}

class _TriggerOperationState {
  _TriggerOperationState()
      : _updatesController = StreamController<TriggerUpdate>.broadcast(),
        _doneCompleter = Completer<TriggerTerminalUpdate>();

  final StreamController<TriggerUpdate> _updatesController;
  final Completer<TriggerTerminalUpdate> _doneCompleter;

  bool finished = false;

  Stream<TriggerUpdate> get updates => _updatesController.stream;

  Future<TriggerTerminalUpdate> get done => _doneCompleter.future;

  void add(TriggerUpdate update) {
    if (finished) {
      return;
    }
    _updatesController.add(update);
  }

  void complete(TriggerTerminalUpdate update) {
    if (_doneCompleter.isCompleted) {
      return;
    }
    _doneCompleter.complete(update);
    unawaited(_updatesController.close());
  }
}
