# Release Checklist

## Preflight

- [ ] Confirm `VERSIONS.md` is updated with current native revisions.
- [ ] Confirm Pigeon sources and generated files are in sync.
- [ ] Confirm README/API examples reflect the current surface.

## Validation

- [ ] `flutter analyze` in:
  - [ ] `packages/nuxie_flutter`
  - [ ] `packages/nuxie_flutter_native`
  - [ ] `packages/nuxie_flutter/example`
- [ ] `dart analyze` in:
  - [ ] `packages/nuxie_flutter_platform_interface`
  - [ ] `packages/mobile_wrapper_contract`
  - [ ] `packages/nuxie_flutter_riverpod`
  - [ ] `packages/nuxie_flutter_bloc`
- [ ] `flutter test` in:
  - [ ] `packages/nuxie_flutter`
  - [ ] `packages/nuxie_flutter_native`
  - [ ] `packages/nuxie_flutter/example`
  - [ ] `packages/nuxie_flutter_riverpod`
  - [ ] `packages/nuxie_flutter_bloc`
- [ ] `dart test` in:
  - [ ] `packages/nuxie_flutter_platform_interface`
  - [ ] `packages/mobile_wrapper_contract`

## Native Spot Checks

- [ ] iOS plugin builds via CocoaPods path.
- [ ] iOS plugin builds via Swift Package Manager path.
- [ ] Android plugin compiles against validated `nuxie-android` revision.

## Publish Prep

- [ ] Bump versions in package `pubspec.yaml` files as needed.
- [ ] Update changelog/release notes with breaking changes and migration notes.
- [ ] Tag commit and push tags.
