# Native Platform Setup

This package is native-first. Flutter wraps native iOS/Android SDKs and depends on correct native setup.

## iOS

Supported package manager paths:

- CocoaPods plugin spec:
  - `packages/nuxie_flutter_native/ios/nuxie_flutter_native.podspec`
- Swift Package Manager package:
  - `packages/nuxie_flutter_native/ios/nuxie_flutter_native/Package.swift`

### Host app requirements

- iOS deployment target `15.0+`
- Native `Nuxie` module must be linked in the app build
- Flutter plugin integration should include generated plugin registration
- If your flows use native permission actions, add the required usage
  descriptions to the host app `Info.plist`

### Notes

- CocoaPods remains supported.
- SPM is also supported.
- If you see `No such module 'Nuxie'`, verify native dependency linkage in the host app.

### iOS permission action keys

Add only the keys that match the flow actions you author:

- `NSUserTrackingUsageDescription` for `request_tracking`
- `NSCameraUsageDescription` for `request_permission("camera")`
- `NSMicrophoneUsageDescription` for `request_permission("microphone")`
- `NSPhotoLibraryUsageDescription` for `request_permission("photos")`
- `NSLocationWhenInUseUsageDescription` for `request_permission("location")`

## Android

### Requirements

- Java 17
- Android SDK installed and configured
- `minSdk 21`
- `NuxieFlowView` hosts should use `FlutterFragmentActivity` or another
  `ComponentActivity` subclass

### SDK setup (example)

```bash
flutter config --android-sdk /opt/homebrew/share/android-commandlinetools
```

Install required SDK components:

```bash
/opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin/sdkmanager \
  --sdk_root=/opt/homebrew/share/android-commandlinetools \
  "platform-tools" \
  "platforms;android-36" \
  "build-tools;36.0.0" \
  "build-tools;28.0.3"
```

Accept licenses:

```bash
yes | /opt/homebrew/share/android-commandlinetools/cmdline-tools/latest/bin/sdkmanager \
  --licenses \
  --sdk_root=/opt/homebrew/share/android-commandlinetools
```

### Standalone plugin compile validation

The plugin Android module can be validated directly:

```bash
/Users/levi/dev/nuxie-dev-5/packages/nuxie-android/gradlew \
  -p packages/nuxie_flutter_native/android \
  assembleDebug
```

The module expects local configuration in `packages/nuxie_flutter_native/android/local.properties`:

```properties
sdk.dir=/path/to/android/sdk
flutter.sdk=/path/to/flutter
```

`local.properties` is intentionally ignored by git.

See [`troubleshooting.md`](troubleshooting.md) for the most common local
Android setup failures.

### Android permission action declarations

`showFlow(...)` works without extra wrapper code changes, but host apps still
need native declarations when flows use permission actions.

Add the permissions your authored flows need:

- `request_permission("camera")` -> `android.permission.CAMERA`
- `request_permission("microphone")` -> `android.permission.RECORD_AUDIO`
- `request_permission("photos")` -> `android.permission.READ_MEDIA_IMAGES`
  on Android 13+ or `android.permission.READ_EXTERNAL_STORAGE` on Android 12
  and below
- `request_permission("location")` -> `android.permission.ACCESS_COARSE_LOCATION`
  and/or `android.permission.ACCESS_FINE_LOCATION`

`request_notifications` uses the native SDK-managed notification permission
path. `request_tracking` is iOS-only and should not be authored for Android
targets.

## Bridge Contract

Pigeon schema source:

- `packages/nuxie_flutter_native/pigeons/nuxie_bridge.dart`

Generated outputs:

- Dart: `packages/nuxie_flutter_native/lib/src/generated/nuxie_bridge.g.dart`
- Kotlin: `packages/nuxie_flutter_native/android/src/main/kotlin/io/nuxie/flutter/nativeplugin/NuxieBridge.g.kt`
- Swift: `packages/nuxie_flutter_native/ios/nuxie_flutter_native/Sources/nuxie_flutter_native/NuxieBridge.g.swift`

Regenerate after schema changes:

```bash
cd packages/nuxie_flutter_native
flutter pub run pigeon --input pigeons/nuxie_bridge.dart
```

For command-level validation matrix, see [`testing.md`](testing.md).
