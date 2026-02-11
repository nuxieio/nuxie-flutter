import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nuxie_flutter/nuxie_flutter.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nuxie Flutter Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage>
    implements NuxiePurchaseController {
  final TextEditingController _apiKeyController =
      TextEditingController(text: 'NX_YOUR_API_KEY');
  final TextEditingController _userIdController =
      TextEditingController(text: 'user_123');
  final TextEditingController _flowIdController =
      TextEditingController(text: 'flow_123');

  final List<String> _logs = <String>[];
  StreamSubscription<TriggerUpdate>? _triggerSubscription;

  Nuxie? _nuxie;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _userIdController.dispose();
    _flowIdController.dispose();
    unawaited(_triggerSubscription?.cancel());
    super.dispose();
  }

  @override
  Future<NuxiePurchaseResult> onPurchase(NuxiePurchaseRequest request) async {
    _addLog('purchase requested: ${request.productId}');
    return NuxiePurchaseResult(
      type: NuxiePurchaseResultType.cancelled,
      message: 'Example purchase controller returns cancelled by default.',
      productId: request.productId,
    );
  }

  @override
  Future<NuxieRestoreResult> onRestore(NuxieRestoreRequest request) async {
    _addLog('restore requested');
    return const NuxieRestoreResult(type: NuxieRestoreResultType.noPurchases);
  }

  Future<void> _initialize() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      _addLog('api key is required');
      return;
    }

    final nuxie = await Nuxie.initialize(
      apiKey: apiKey,
      purchaseController: this,
      options: const NuxieOptions(environment: NuxieEnvironment.staging),
    );

    setState(() {
      _nuxie = nuxie;
    });

    _addLog('initialized sdk version=${nuxie.sdkVersion}');
  }

  Future<void> _identify() async {
    final nuxie = _nuxie;
    if (nuxie == null) {
      _addLog('initialize first');
      return;
    }

    await nuxie.identify(
      _userIdController.text.trim(),
      userProperties: const <String, Object?>{'plan': 'pro'},
    );
    _addLog('identify sent');
  }

  Future<void> _trigger() async {
    final nuxie = _nuxie;
    if (nuxie == null) {
      _addLog('initialize first');
      return;
    }

    await _triggerSubscription?.cancel();

    final op = nuxie.trigger('paywall_tapped');
    _triggerSubscription = op.updates.listen((update) {
      _addLog('trigger update: ${update.kind} terminal=${update.isTerminal}');
    });

    final terminal = await op.done;
    _addLog('trigger done: ${terminal.kind}');
  }

  Future<void> _triggerOnce() async {
    final nuxie = _nuxie;
    if (nuxie == null) {
      _addLog('initialize first');
      return;
    }

    final terminal = await nuxie.triggerOnce(
      'paywall_tapped',
      timeout: const Duration(seconds: 10),
    );
    _addLog('triggerOnce terminal: ${terminal.kind}');
  }

  Future<void> _showFlow() async {
    final nuxie = _nuxie;
    if (nuxie == null) {
      _addLog('initialize first');
      return;
    }

    await nuxie.showFlow(_flowIdController.text.trim());
    _addLog('showFlow called');
  }

  Future<void> _hasFeature() async {
    final nuxie = _nuxie;
    if (nuxie == null) {
      _addLog('initialize first');
      return;
    }

    final access = await nuxie.hasFeature('premium_feature');
    _addLog('feature allowed=${access.allowed} balance=${access.balance}');
  }

  void _addLog(String value) {
    setState(() {
      _logs.insert(0, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuxie Flutter Example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(labelText: 'API key'),
            ),
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(labelText: 'Distinct ID'),
            ),
            TextField(
              controller: _flowIdController,
              decoration: const InputDecoration(labelText: 'Flow ID'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ElevatedButton(
                  onPressed: _initialize,
                  child: const Text('Initialize'),
                ),
                ElevatedButton(
                  onPressed: _identify,
                  child: const Text('Identify'),
                ),
                ElevatedButton(
                  onPressed: _trigger,
                  child: const Text('Trigger'),
                ),
                ElevatedButton(
                  onPressed: _triggerOnce,
                  child: const Text('Trigger Once'),
                ),
                ElevatedButton(
                  onPressed: _showFlow,
                  child: const Text('Show Flow'),
                ),
                ElevatedButton(
                  onPressed: _hasFeature,
                  child: const Text('Has Feature'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Configured: ${_nuxie != null}'),
            const SizedBox(height: 8),
            const Text('Logs:'),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (BuildContext context, int index) {
                  return Text(_logs[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
