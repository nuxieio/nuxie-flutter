# API reference

## Initialization

```dart
Future<Nuxie> Nuxie.initialize({
  required String apiKey,
  NuxieOptions? options,
  NuxiePurchaseController? purchaseController,
  String wrapperVersion = '0.1.0',
});
```

`NuxieOptions` contains only customer-owned settings: environment, log level,
console logging, sensitive-data redaction, locale, purchase handling mode, and
the iOS development Test Store switch.

## Lifecycle and identity

- `shutdown()`
- `identify(distinctId, {userProperties, userPropertiesSetOnce})`
- `reset({keepAnonymousId = false})`
- `getDistinctId()`
- `getAnonymousId()`
- `getIsIdentified()`

## Events and presentation

- `trigger(event, {properties}) -> void`
- `dismiss()`
- `setLocaleIdentifier(localeIdentifier)`

Journey decisions are native-owned. `trigger` does not return a match,
presentation result, handle, or cancellation token.

## Features

- `featureAccessChanges`
- `hasFeature(featureId, {requiredBalance = 1, entityId, policy})`
- `useFeature(featureId, {amount = 1, entityId, metadata}) -> void`
- `useFeatureAndWait(featureId, {amount = 1, entityId, setUsage, metadata})`

`FeatureCheckPolicy` is `cacheFirst` or `remote`. Balances and usage values are
`double`. Atomic usage results include `authoritativeAccess`.

## Native callbacks

- `activities: Stream<NuxieActivityInfo>`
- `appActions: Stream<AppAction>`
- `purchaseRequests: Stream<NuxiePurchaseRequest>`
- `restoreRequests: Stream<NuxieRestoreRequest>`

`AppAction` carries a name, scalar payload, and `ExperienceRef` with Experience
identity and optional Journey identity.

## Commerce

`NuxiePurchaseController.purchase` returns `NuxiePurchaseResult` with
`purchased`, `cancelled`, `pending`, or `failed`.
`NuxiePurchaseController.restore` returns `NuxieRestoreResult` with `restored`,
`noPurchases`, or `failed`.
