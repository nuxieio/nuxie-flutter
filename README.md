# Nuxie Flutter SDK

Native-first Flutter wrapper for Nuxie.

This SDK keeps runtime logic on native iOS/Android and exposes an ergonomic, typed Dart API.

- iOS runtime: `NuxieSDK` from `nuxie-ios`
- Android runtime: `NuxieSDK` from `nuxie-android`
- Flutter bridge: Pigeon-generated typed bridge + platform interface

## Documentation Index

- Quickstart: [`docs/quickstart.md`](docs/quickstart.md)
- API reference: [`docs/api-reference.md`](docs/api-reference.md)
- Native platform setup: [`docs/native-setup.md`](docs/native-setup.md)
- Riverpod/Bloc adapters: [`docs/adapters.md`](docs/adapters.md)
- Architecture: [`docs/architecture.md`](docs/architecture.md)
- Testing and validation: [`docs/testing.md`](docs/testing.md)
- Troubleshooting: [`docs/troubleshooting.md`](docs/troubleshooting.md)
- Example app: [`packages/nuxie_flutter/example`](packages/nuxie_flutter/example)
- Release process: [`RELEASE_CHECKLIST.md`](RELEASE_CHECKLIST.md)
- Version map: [`VERSIONS.md`](VERSIONS.md)
- Migration notes: [`MIGRATION.md`](MIGRATION.md)

## Repository Layout

- `packages/nuxie_flutter`: app-facing API
- `packages/nuxie_flutter_platform_interface`: shared models + abstract platform contract
- `packages/nuxie_flutter_native`: iOS/Android implementation
- `packages/nuxie_flutter_riverpod`: optional Riverpod adapter package
- `packages/nuxie_flutter_bloc`: optional Bloc/Cubit adapter package
- `packages/mobile_wrapper_contract`: shared Expo/Flutter contract fixtures

## Compatibility

- Dart: `>=3.3.0 <4.0.0`
- Flutter: `>=3.19.0`
- Android: `minSdk 21`
- iOS: `15.0+`

## Install

This repository is currently organized for workspace/path consumption. In your
Flutter app:

```yaml
dependencies:
  nuxie_flutter:
    path: packages/nuxie_flutter
```

Optional adapters:

```yaml
dependencies:
  nuxie_flutter_riverpod:
    path: packages/nuxie_flutter_riverpod
  nuxie_flutter_bloc:
    path: packages/nuxie_flutter_bloc
```

## 60-Second Quickstart

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

```dart
final nuxie = Nuxie.instance;

await nuxie.identify('user_123');
final trigger = nuxie.trigger('paywall_tapped');
trigger.updates.listen((update) {
  // optional progressive updates
});
final terminal = await trigger.done;

if (terminal is TriggerDecisionUpdate) {
  // handle terminal decision
}
```

## Key Concepts

- `Nuxie.initialize(...)`: one-time configuration; returns singleton instance.
- `Nuxie.instance`: shared client after configuration.
- `trigger(...)`: progressive stream (`updates`) + terminal future (`done`).
- `triggerOnce(...)`: convenience terminal-only trigger API.
- `showFlow(flowId)`: native full-screen flow presentation.
- `NuxieFlowView`: embedded native flow view for custom layouts.
- `NuxiePurchaseController`: Dart purchase/restore bridge for flow purchase actions.
- `NuxieFeatureBuilder`: widget helper for feature gating in UI trees.

## Purchase Bridge

Pass a purchase controller during initialization:

```dart
await Nuxie.initialize(
  apiKey: 'NX_YOUR_API_KEY',
  purchaseController: MyPurchaseController(),
);
```

```dart
class MyPurchaseController implements NuxiePurchaseController {
  @override
  Future<NuxiePurchaseResult> onPurchase(NuxiePurchaseRequest request) async {
    // call billing provider and map to NuxiePurchaseResult
    return NuxiePurchaseResult(
      type: NuxiePurchaseResultType.success,
      productId: request.productId,
    );
  }

  @override
  Future<NuxieRestoreResult> onRestore(NuxieRestoreRequest request) async {
    return const NuxieRestoreResult(type: NuxieRestoreResultType.success);
  }
}
```

## Native Setup Notes

- iOS CocoaPods support: `packages/nuxie_flutter_native/ios/nuxie_flutter_native.podspec`
- iOS SPM support: `packages/nuxie_flutter_native/ios/nuxie_flutter_native/Package.swift`
- Android plugin validation can be run with:

```bash
/Users/levi/dev/nuxie-dev-5/packages/nuxie-android/gradlew \
  -p packages/nuxie_flutter_native/android \
  assembleDebug
```

See full setup details in [`docs/native-setup.md`](docs/native-setup.md).

## Example App

The example app includes a one-click sanity flow that exercises:

- `initialize`
- `identify`
- `triggerOnce`
- feature access + usage APIs
- queue APIs (`getQueuedEventCount`, `flushEvents`)
- flow embedding via `NuxieFlowView`

Run:

```bash
cd packages/nuxie_flutter/example
flutter pub get
flutter run
```

## Development

From this repository root:

```bash
cd packages/nuxie_flutter
flutter analyze
flutter test
```

Optional (if `melos` is installed in your environment): run workspace-wide
analyze/test via `melos run analyze` and `melos run test`.

Regenerate Pigeon bridge after schema updates:

```bash
cd packages/nuxie_flutter_native
flutter pub run pigeon --input pigeons/nuxie_bridge.dart
```
