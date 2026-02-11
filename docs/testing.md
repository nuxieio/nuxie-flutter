# Testing And Validation

This repository uses package-level tests plus native compile checks.

## Fast Path (Core API)

```bash
cd packages/nuxie_flutter
flutter analyze
flutter test
```

## Full Package Sweep

```bash
cd packages/mobile_wrapper_contract
dart analyze
dart test

cd ../nuxie_flutter_platform_interface
dart analyze
dart test

cd ../nuxie_flutter_native
flutter analyze
flutter test

cd ../nuxie_flutter
flutter analyze
flutter test

cd ../nuxie_flutter_riverpod
flutter analyze
flutter test

cd ../nuxie_flutter_bloc
flutter analyze
flutter test

cd ../nuxie_flutter/example
flutter analyze
flutter test
```

## Android Native Compile Validation

Use this when validating Android plugin wiring independent of example runtime:

```bash
/Users/levi/dev/nuxie-dev-5/packages/nuxie-android/gradlew \
  -p packages/nuxie_flutter_native/android \
  assembleDebug
```

Requirements:

- Java 17
- `local.properties` in `packages/nuxie_flutter_native/android` with:
  - `sdk.dir=/path/to/android/sdk`
  - `flutter.sdk=/path/to/flutter`

## iOS Native Validation

- CocoaPods path: ensure plugin podspec resolves in a host Flutter iOS build.
- SPM path: ensure package in
  `packages/nuxie_flutter_native/ios/nuxie_flutter_native/Package.swift`
  resolves in Xcode.

## Contract Regression Coverage

`packages/mobile_wrapper_contract` includes fixture-backed tests that verify
normalized trigger and purchase contracts stay stable across wrappers.

Run:

```bash
cd packages/mobile_wrapper_contract
dart test
```
