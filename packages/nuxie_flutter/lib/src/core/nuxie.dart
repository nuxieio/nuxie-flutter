import 'dart:async';

import 'package:nuxie_flutter_native/nuxie_flutter_native.dart';
import 'package:nuxie_flutter_platform_interface/nuxie_flutter_platform_interface.dart';

class Nuxie {
  Nuxie._({required this.platform});

  static Nuxie? _instance;

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
  }) async {
    registerNuxieFlutterNative();

    final platform = NuxieFlutterPlatform.instance;
    await platform.configure(
      apiKey: apiKey,
      options: options,
      usingPurchaseController: purchaseController != null,
      wrapperVersion: wrapperVersion,
    );

    final nuxie = Nuxie._(platform: platform)
      .._purchaseController = purchaseController;
    _instance = nuxie;
    return nuxie;
  }

  final NuxieFlutterPlatform platform;

  NuxiePurchaseController? _purchaseController;

  NuxiePurchaseController? get purchaseController => _purchaseController;

  bool _isConfigured = true;

  bool get isConfigured => _isConfigured;

  String get sdkVersion => '0.1.0';

  Stream<FeatureAccessChangedEvent> get featureAccessChanges =>
      platform.featureAccessChanges;

  Stream<NuxieFlowLifecycleEvent> get flowLifecycleEvents =>
      platform.flowLifecycleEvents;

  Stream<NuxieLogEvent> get logEvents => platform.logEvents;

  Future<void> shutdown() async {
    await platform.shutdown();
    _isConfigured = false;
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
