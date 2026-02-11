# API Reference

Primary export:

```dart
import 'package:nuxie_flutter/nuxie_flutter.dart';
```

This export also re-exports all shared model/event classes from
`nuxie_flutter_platform_interface`.

## Nuxie

### Static

- `Nuxie.initialize({required apiKey, options, purchaseController, wrapperVersion, platformOverride})`
- `Nuxie.instance`

### Properties

- `isConfigured`
- `sdkVersion`
- `purchaseController`
- `featureAccessChanges`
- `flowLifecycleEvents`
- `logEvents`
- `triggerUpdates`
- `purchaseRequests`
- `restoreRequests`

### Identity

- `identify(distinctId, {userProperties, userPropertiesSetOnce})`
- `reset({keepAnonymousId = true})`
- `getDistinctId()`
- `getAnonymousId()`
- `getIsIdentified()`

### Trigger / Journey

- `trigger(event, {properties, userProperties, userPropertiesSetOnce})`
- `triggerOnce(event, {properties, userProperties, userPropertiesSetOnce, timeout})`
- `showFlow(flowId)`

### Profile

- `refreshProfile()`

### Features

- `hasFeature(featureId, {requiredBalance, entityId})`
- `getCachedFeature(featureId, {entityId})`
- `checkFeature(featureId, {requiredBalance, entityId})`
- `refreshFeature(featureId, {requiredBalance, entityId})`
- `useFeature(featureId, {amount = 1, entityId, metadata})`
- `useFeatureAndWait(featureId, {amount = 1, entityId, setUsage = false, metadata})`

### Queue

- `flushEvents()`
- `getQueuedEventCount()`
- `pauseEventQueue()`
- `resumeEventQueue()`

### Lifecycle

- `shutdown()`
- `setPurchaseController(controller)`

## NuxieTriggerOperation

- `requestId`
- `updates` (`Stream<TriggerUpdate>`)
- `done` (`Future<TriggerTerminalUpdate>`)
- `cancel()`

## Widgets

- `NuxieBuilder`
  - Lightweight helper to access configured `Nuxie.instance` in widget trees.
  - Optional `unconfiguredBuilder` fallback.
- `NuxieFeatureBuilder`
  - Reactive helper that does initial `hasFeature(...)` then listens to
    `featureAccessChanges`.
- `NuxieFlowView`
  - Embedded native flow view for iOS/Android.
  - For unsupported targets, renders provided `placeholder` (or default text).

## Trigger Models

- `TriggerUpdate` variants:
  - `TriggerDecisionUpdate`
  - `TriggerEntitlementUpdate`
  - `TriggerJourneyUpdate`
  - `TriggerErrorUpdate`
- `TriggerTerminalUpdate` is an alias of `TriggerUpdate`.

Terminal behavior:

- terminal on any `TriggerErrorUpdate`
- terminal on `TriggerJourneyUpdate`
- terminal on decision kinds:
  - `allowedImmediate`
  - `deniedImmediate`
  - `noMatch`
  - `suppressed`
- terminal on entitlement kinds:
  - `allowed`
  - `denied`

## Feature Models

- `FeatureAccess`
  - `allowed`
  - `unlimited`
  - `balance`
  - `type` (`boolean`, `metered`, `creditSystem`)
- `FeatureCheckResult`
- `FeatureUsageResult`

## Purchase Bridge

Implement `NuxiePurchaseController`:

```dart
abstract class NuxiePurchaseController {
  Future<NuxiePurchaseResult> onPurchase(NuxiePurchaseRequest request);
  Future<NuxieRestoreResult> onRestore(NuxieRestoreRequest request);
}
```

Result enums:

- `NuxiePurchaseResultType`: `success`, `cancelled`, `pending`, `failed`
- `NuxieRestoreResultType`: `success`, `noPurchases`, `failed`

## Options

`NuxieOptions` fields include:

- environment + endpoint
- logging controls
- retry and batch settings
- queue and cache limits
- locale and debug mode
- event linking policy
- flow cache/download settings
- purchase timeout

See source for full field list:

- `packages/nuxie_flutter_platform_interface/lib/src/models/nuxie_options.dart`

## Errors

API calls can throw `NuxieException`:

- `code`
- `message`
- `details` (optional)

## Optional Adapter APIs

Riverpod package (`nuxie_flutter_riverpod`):

- `nuxieProvider`
- `NuxieFeatureQuery`
- `nuxieFeatureProvider`

Bloc package (`nuxie_flutter_bloc`):

- `FeatureAccessCubit`
