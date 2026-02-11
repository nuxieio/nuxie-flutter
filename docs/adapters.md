# Optional State Management Adapters

`nuxie_flutter` is intentionally framework-agnostic. For teams standardizing on
Riverpod or Bloc, this repository ships optional adapters so apps do not need
to duplicate common wiring.

## Packages

- `packages/nuxie_flutter_riverpod`
- `packages/nuxie_flutter_bloc`

These are optional and can be omitted if your app uses another state
management strategy.

## Riverpod Adapter

Install:

```yaml
dependencies:
  nuxie_flutter:
    path: ../nuxie_flutter
  nuxie_flutter_riverpod:
    path: ../nuxie_flutter_riverpod
```

Use:

```dart
import 'package:nuxie_flutter_riverpod/nuxie_flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';

const query = NuxieFeatureQuery(
  'premium_feature',
  requiredBalance: 1,
);

final accessAsync = ref.watch(nuxieFeatureProvider(query));
```

Behavior:

- `nuxieProvider` exposes `Nuxie.instance`.
- `nuxieFeatureProvider` performs an initial `hasFeature` fetch, then listens to
  `featureAccessChanges` for live updates.
- Provider family keys include `featureId`, `requiredBalance`, and `entityId`.

## Bloc Adapter

Install:

```yaml
dependencies:
  nuxie_flutter:
    path: ../nuxie_flutter
  nuxie_flutter_bloc:
    path: ../nuxie_flutter_bloc
```

Use:

```dart
import 'package:nuxie_flutter/nuxie_flutter.dart';
import 'package:nuxie_flutter_bloc/nuxie_flutter_bloc.dart';

final cubit = FeatureAccessCubit(
  Nuxie.instance,
  'premium_feature',
  requiredBalance: 1,
);
```

Behavior:

- `FeatureAccessCubit` can auto-refresh on startup (`autoRefresh = true`).
- It listens to `featureAccessChanges` and emits when matching `featureId`
  updates arrive.
- Call `refresh()` manually when you need on-demand rechecks.

## Choosing One

- Use Riverpod adapter when your app already models UI through providers.
- Use Bloc adapter when feature access belongs in Cubit/BLoC orchestration.
- Use neither when you want direct control over streams and caching.

## Notes

- Adapters are wrappers only; business logic remains in native iOS/Android SDKs.
- Keep adapter package version aligned with the same `nuxie_flutter` release.
