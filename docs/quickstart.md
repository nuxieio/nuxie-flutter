# Quickstart

## Configure

```dart
final nuxie = await Nuxie.initialize(
  apiKey: 'NX_PROD_...',
  options: const NuxieOptions(
    environment: NuxieEnvironment.production,
  ),
);
```

## Identify

```dart
await nuxie.identify(
  'user_123',
  userProperties: <String, Object?>{'plan': 'pro'},
);
```

## Capture an event

```dart
nuxie.trigger(
  'upgrade_tapped',
  properties: <String, Object?>{'source': 'settings'},
);
```

The call returns immediately. The native Journey runtime evaluates the event
in its durable ordered lane.

## Observe native output

```dart
nuxie.activities.listen((event) {
  analytics.track(event.name, event.properties);
});

nuxie.appActions.listen((action) {
  appActions.handle(action.name, action.payload);
});
```

## Check and use a Feature

```dart
final access = await nuxie.hasFeature(
  'ai_credits',
  requiredBalance: 2.5,
  policy: FeatureCheckPolicy.remote,
);

if (access.allowed) {
  await nuxie.useFeatureAndWait('ai_credits', amount: 2.5);
}
```

## Shut down

```dart
await nuxie.shutdown();
```
