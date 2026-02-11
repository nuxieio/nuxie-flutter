# Nuxie Flutter SDK

Native-first Flutter wrapper for Nuxie.

- iOS native runtime: `NuxieSDK` from `nuxie-ios`
- Android native runtime: `NuxieSDK` from `nuxie-android`
- Flutter layer: typed Dart API + Pigeon bridge, no duplicated journey/entitlement logic

## Package Layout

- `packages/nuxie_flutter`: app-facing Dart API
- `packages/nuxie_flutter_platform_interface`: shared models + platform contract
- `packages/nuxie_flutter_native`: endorsed iOS/Android bridge implementation
- `packages/nuxie_flutter_riverpod`: optional Riverpod adapters
- `packages/nuxie_flutter_bloc`: optional Bloc/Cubit adapters
- `packages/mobile_wrapper_contract`: shared wrapper contract fixtures (Expo/Flutter anti-drift)

## Compatibility

- Dart: `>=3.3.0 <4.0.0`
- Flutter: `>=3.19.0`
- Android: `minSdk 21` (from native Android SDK)
- iOS: `15.0+` (from native iOS SDK)

## Install (workspace path dependency)

```yaml
dependencies:
  nuxie_flutter:
    path: packages/nuxie_flutter
```

## Quick Start

```dart
import 'package:nuxie_flutter/nuxie_flutter.dart';

Future<void> bootstrapNuxie() async {
  await Nuxie.initialize(
    apiKey: 'NX_...',
    options: const NuxieOptions(
      environment: NuxieEnvironment.production,
    ),
    purchaseController: MyPurchaseController(), // optional
  );
}
```

Core usage:

```dart
final nuxie = Nuxie.instance;
await nuxie.identify('user_123');
final op = nuxie.trigger('paywall_tapped');
final terminal = await op.done;
await nuxie.showFlow('flow_123');
```

## Purchase Bridge

When `purchaseController` is provided in `initialize(...)`, native purchase/restore requests from flows are forwarded to Dart:

```dart
class MyPurchaseController implements NuxiePurchaseController {
  @override
  Future<NuxiePurchaseResult> onPurchase(NuxiePurchaseRequest request) async {
    // Call your billing layer here.
    return NuxiePurchaseResult(
      type: NuxiePurchaseResultType.success,
      productId: request.productId,
    );
  }

  @override
  Future<NuxieRestoreResult> onRestore(NuxieRestoreRequest request) async {
    return const NuxieRestoreResult(type: NuxieRestoreResultType.noPurchases);
  }
}
```

## Optional Adapters

- Riverpod: `packages/nuxie_flutter_riverpod`
- Bloc/Cubit: `packages/nuxie_flutter_bloc`

These are intentionally separate optional packages so app teams can choose their own state management approach.

## Embedded Flow Widget

`NuxieFlowView` is available for embedding native flow UI:

```dart
const NuxieFlowView(flowId: 'flow_123');
```

`showFlow(flowId)` remains the default full-screen presentation path.

## iOS Package Managers

- CocoaPods: supported via `packages/nuxie_flutter_native/ios/nuxie_flutter_native.podspec`
- Swift Package Manager: supported via `packages/nuxie_flutter_native/ios/nuxie_flutter_native/Package.swift`

For CocoaPods app projects, ensure the native `Nuxie` iOS SDK module is linked in the host app (for example via Xcode Swift Package dependencies) so the bridge can import `Nuxie`.

## Development

From repo root:

```bash
flutter pub get
flutter analyze
flutter test
```

Generate bridge code after editing Pigeon schema:

```bash
flutter pub run pigeon \
  --input packages/nuxie_flutter_native/pigeons/nuxie_bridge.dart
```

## Release Artifacts

- Version mapping: `VERSIONS.md`
- Release process: `RELEASE_CHECKLIST.md`
- Migration notes: `MIGRATION.md`
