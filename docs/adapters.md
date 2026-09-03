# State-management adapters

## Bloc

`FeatureAccessCubit` performs a policy-aware initial Feature check and follows
`featureAccessChanges` for the requested Feature.

```dart
final cubit = FeatureAccessCubit(
  Nuxie.instance,
  'ai_credits',
  requiredBalance: 2.5,
  policy: FeatureCheckPolicy.remote,
);
```

## Riverpod

`nuxieFeatureProvider` exposes the same initial check plus reactive updates.

```dart
final query = NuxieFeatureQuery(
  'ai_credits',
  requiredBalance: 2.5,
  policy: FeatureCheckPolicy.cacheFirst,
);
```

Both adapters preserve `double` balances and use the shared native Feature
stream. They do not add decision or persistence behavior.
