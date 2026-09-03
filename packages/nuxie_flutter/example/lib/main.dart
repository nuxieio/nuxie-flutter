import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nuxie_flutter/nuxie_flutter.dart';

void main() {
  runApp(const NuxieExampleApp());
}

class NuxieExampleApp extends StatelessWidget {
  const NuxieExampleApp({super.key, this.initializeSdk = true});

  final bool initializeSdk;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nuxie Flutter Example',
      home: DemoScreen(initializeSdk: initializeSdk),
    );
  }
}

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key, required this.initializeSdk});

  final bool initializeSdk;

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  Nuxie? _nuxie;
  FeatureAccess? _feature;
  String? _error;
  final List<String> _activity = <String>[];
  StreamSubscription<NuxieActivityInfo>? _activitySubscription;
  StreamSubscription<AppAction>? _actionSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.initializeSdk) {
      unawaited(_initialize());
    }
  }

  Future<void> _initialize() async {
    try {
      final nuxie = await Nuxie.initialize(
        apiKey: const String.fromEnvironment(
          'NUXIE_API_KEY',
          defaultValue: 'NX_DEVELOPMENT_KEY',
        ),
        options: const NuxieOptions(
          environment: NuxieEnvironment.development,
          logLevel: NuxieLogLevel.debug,
        ),
        purchaseController: const _ExamplePurchaseController(),
      );
      _activitySubscription = nuxie.activities.listen((event) {
        _append('activity ${event.name}');
      });
      _actionSubscription = nuxie.appActions.listen((action) {
        _append('app action ${action.name}');
      });
      if (mounted) {
        setState(() => _nuxie = nuxie);
      }
      await _loadFeature();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  Future<void> _loadFeature() async {
    final nuxie = _nuxie;
    if (nuxie == null) return;
    try {
      final feature = await nuxie.hasFeature(
        'pro_export',
        policy: FeatureCheckPolicy.remote,
      );
      if (mounted) {
        setState(() => _feature = feature);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  void _captureEvent() {
    _nuxie?.trigger(
      'paywall_opened',
      properties: <String, Object?>{'source': 'flutter_example'},
    );
    _append('event captured');
  }

  void _append(String value) {
    if (!mounted) return;
    setState(() {
      _activity.insert(0, value);
      if (_activity.length > 20) _activity.removeLast();
    });
  }

  @override
  void dispose() {
    unawaited(_activitySubscription?.cancel());
    unawaited(_actionSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuxie Flutter Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Configured: ${_nuxie?.isConfigured ?? false}'),
          Text('Feature allowed: ${_feature?.allowed ?? false}'),
          Text('Feature balance: ${_feature?.balance ?? 'n/a'}'),
          if (_error != null) Text('Error: $_error'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _nuxie == null ? null : _captureEvent,
            child: const Text('Capture Event'),
          ),
          OutlinedButton(
            onPressed: _nuxie == null ? null : _loadFeature,
            child: const Text('Load Feature'),
          ),
          const SizedBox(height: 12),
          const Text('Recent native activity'),
          for (final event in _activity) Text(event),
        ],
      ),
    );
  }
}

class _ExamplePurchaseController implements NuxiePurchaseController {
  const _ExamplePurchaseController();

  @override
  Future<NuxiePurchaseResult> purchase(NuxiePurchaseRequest request) async {
    return const NuxiePurchaseResult(
      type: NuxiePurchaseResultType.cancelled,
    );
  }

  @override
  Future<NuxieRestoreResult> restore(NuxieRestoreRequest request) async {
    return const NuxieRestoreResult(
      type: NuxieRestoreResultType.noPurchases,
    );
  }
}
