# Architecture

Nuxie Flutter is a native-first federated plugin. Dart does not re-implement
runtime business logic; it forwards typed requests to the native SDKs.

## Package Layout

- `packages/nuxie_flutter`
  - App-facing API, singleton lifecycle, widgets (`NuxieFlowView`,
    `NuxieFeatureBuilder`, `NuxieBuilder`)
- `packages/nuxie_flutter_platform_interface`
  - Shared models, errors, event types, and platform contract
- `packages/nuxie_flutter_native`
  - Endorsed iOS/Android implementation and Pigeon bridge code
- `packages/nuxie_flutter_riverpod`
  - Optional Riverpod adapter
- `packages/nuxie_flutter_bloc`
  - Optional Bloc adapter
- `packages/mobile_wrapper_contract`
  - Shared mobile wrapper fixtures and contract normalization used by Flutter
    and other mobile wrappers

## Request Path

1. App calls `Nuxie.instance` API from Dart.
2. `nuxie_flutter` invokes `NuxieFlutterPlatform` methods.
3. `nuxie_flutter_native` maps platform interface types to generated Pigeon
   types.
4. Native Swift/Kotlin plugin forwards into native Nuxie SDKs.
5. Native SDKs emit updates and results back through event channels.
6. Dart maps updates into typed `TriggerUpdate`, `FeatureAccessChangedEvent`,
   and other model classes.

## Trigger Operation Model

- `trigger(...)` returns `NuxieTriggerOperation`.
- `updates` exposes progressive update events.
- `done` resolves once on the terminal update.
- `cancel()` maps to native trigger cancellation.

Terminal handling is centralized in Dart only to provide ergonomic stream/future
coordination. Decision and entitlement semantics remain native-owned.

## Purchase Bridge

When a purchase controller is attached:

- Native emits purchase/restore request events.
- Dart delegates to `NuxiePurchaseController`.
- Dart sends completion payloads back to native through
  `completePurchase/completeRestore`.

This keeps billing-provider specifics in app code while preserving native flow
control.

## Why `mobile_wrapper_contract` Is a Package

Shared fixtures and contract shape rules live in
`packages/mobile_wrapper_contract` (not `specs/`) because they are executable
test assets:

- consumed by Dart tests
- versioned with implementation changes
- reusable by multiple wrapper implementations

`specs/` remains design documentation; contract fixtures remain code artifacts.
