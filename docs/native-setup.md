# Native setup

## iOS

The plugin podspec depends on `Nuxie` `0.1.0`, and its Swift package manifest
uses the same exact release. Set iOS 15 or newer, then install pods normally:

```bash
cd ios
pod install
```

The Test Store option is intended only for development builds.

## Android

The plugin depends on `ai.nuxie:nuxie-android:0.1.0`, requires API 23 or newer,
and compiles with SDK 36. Ensure `google()` and `mavenCentral()` are available
to dependency resolution.

## Generated channel

Edit only `packages/nuxie_flutter_native/pigeons/nuxie_bridge.dart`, then run:

```bash
cd packages/nuxie_flutter_native
flutter pub get
flutter pub run pigeon --input pigeons/nuxie_bridge.dart
```

Commit the generated Dart, Swift, and Kotlin outputs with the source schema.
