# nuxie_flutter_example

Reference app for the Nuxie Flutter SDK.

## What It Covers

- `Nuxie.initialize(...)`
- `identify(...)`
- `trigger(...)` and `triggerOnce(...)`
- `showFlow(...)`
- `hasFeature(...)`
- `useFeatureAndWait(...)`
- event queue APIs (`getQueuedEventCount`, `flushEvents`)
- optional embedded `NuxieFlowView`
- Dart-side purchase and restore controller callbacks
- end-to-end "Run sanity check" action in the UI

## Run

```bash
cd packages/nuxie_flutter/example
flutter pub get
flutter run
```

## Notes

- The default API key field uses a placeholder (`NX_YOUR_API_KEY`).
- Use a valid key/environment pair to exercise real backend behavior.
