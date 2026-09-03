# Nuxie Flutter SDK

Flutter bindings for the Nuxie iOS and Android SDKs. Journey evaluation,
Experience presentation, Features, identity, and commerce remain native. This
workspace provides a thin generated platform channel, a Dart facade, and
optional Bloc and Riverpod adapters.

## Packages

- `nuxie_flutter`: app-facing API and widgets.
- `nuxie_flutter_platform_interface`: portable models and platform seam.
- `nuxie_flutter_native`: generated Pigeon channel plus Swift and Kotlin hosts.
- `nuxie_flutter_bloc`: optional `FeatureAccessCubit`.
- `nuxie_flutter_riverpod`: optional Feature providers.

## Install

```yaml
dependencies:
  nuxie_flutter: ^0.1.0
```

The native plugin pins Nuxie iOS and Android `0.1.0` exactly. iOS applications
run `pod install`; Android applications resolve the native artifact from
Maven Central.

## Configure

```dart
final nuxie = await Nuxie.initialize(
  apiKey: 'NX_PROD_...',
  options: const NuxieOptions(
    environment: NuxieEnvironment.production,
    logLevel: NuxieLogLevel.info,
  ),
);
```

## Capture events and run Journeys

```dart
nuxie.trigger(
  'paywall_opened',
  properties: <String, Object?>{'source': 'settings'},
);
```

`trigger` is event-only and fire-and-forget. Matching Journeys run in native
code and present Experiences as their authored programs advance. Use
`dismiss()` to close the active Experience.

## Features

```dart
final access = await nuxie.hasFeature(
  'ai_credits',
  requiredBalance: 2.5,
  policy: FeatureCheckPolicy.remote,
);

if (access.allowed) {
  final result = await nuxie.useFeatureAndWait(
    'ai_credits',
    amount: 2.5,
  );
  print(result.authoritativeAccess);
}
```

Feature balances preserve fractional values. Subscribe to
`featureAccessChanges` for reactive updates.

## Native activity and App Actions

```dart
nuxie.activities.listen((activity) {
  analytics.track(activity.name, activity.properties);
});

nuxie.appActions.listen((action) {
  if (action.name == 'open_settings') {
    navigation.openSettings(action.payload);
  }
});
```

## Commerce

Pass a `NuxiePurchaseController` during initialization when the app owns
checkout. Requests mirror the portable snake-case native wire without adding
receipt or transaction fields. Purchase results are `purchased`, `cancelled`,
`pending`, or `failed`; restore results are `restored`, `no_purchases`, or
`failed`.

## Validate

```bash
flutter analyze
flutter test
```

Regenerate channels after editing the Pigeon source:

```bash
cd packages/nuxie_flutter_native
flutter pub run pigeon --input pigeons/nuxie_bridge.dart
```

See [Quickstart](docs/quickstart.md), [API Reference](docs/api-reference.md),
and [Native Setup](docs/native-setup.md).
