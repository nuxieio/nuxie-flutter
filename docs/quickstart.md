# Quickstart

This guide gets Nuxie running in a Flutter app with identity, trigger handling, and feature checks.

## 1. Add Dependency

```yaml
dependencies:
  nuxie_flutter:
    path: ../nuxie_flutter
```

## 2. Initialize Once

```dart
import 'package:nuxie_flutter/nuxie_flutter.dart';

Future<void> configureNuxie() async {
  await Nuxie.initialize(
    apiKey: 'NX_YOUR_API_KEY',
    options: const NuxieOptions(
      environment: NuxieEnvironment.production,
    ),
  );
}
```

Call this early in app startup before using `Nuxie.instance`.

If native project setup is incomplete, see [`native-setup.md`](native-setup.md)
before continuing.

## 3. Identify User

```dart
final nuxie = Nuxie.instance;
await nuxie.identify(
  'user_123',
  userProperties: const {
    'plan': 'pro',
    'region': 'us',
  },
);
```

Reset when needed:

```dart
await nuxie.reset();
```

## 4. Trigger Journeys

Use full streaming mode when you want progressive updates:

```dart
final op = nuxie.trigger('paywall_tapped');

final sub = op.updates.listen((update) {
  // non-terminal and terminal updates
});

final terminal = await op.done;
await sub.cancel();
```

Use terminal-only mode for simple flows:

```dart
final terminal = await nuxie.triggerOnce(
  'paywall_tapped',
  timeout: const Duration(seconds: 10),
);
```

## 5. Show a Flow

```dart
await nuxie.showFlow('flow_123');
```

Or embed in UI:

```dart
const NuxieFlowView(flowId: 'flow_123');
```

## 6. Feature Access and Usage

```dart
final access = await nuxie.hasFeature('premium_feature');

if (access.allowed) {
  final usage = await nuxie.useFeatureAndWait(
    'premium_feature',
    amount: 1,
  );
}
```

## 7. Queue Operations

```dart
final queued = await nuxie.getQueuedEventCount();
final flushed = await nuxie.flushEvents();
```

## 8. Shutdown (optional)

```dart
await nuxie.shutdown();
```

For production apps, this is typically only needed in explicit teardown/testing contexts.

## Next Steps

- Add Riverpod/Bloc glue with [`adapters.md`](adapters.md) if needed.
- Review common setup/runtime errors in [`troubleshooting.md`](troubleshooting.md).
- See complete API surface in [`api-reference.md`](api-reference.md).
