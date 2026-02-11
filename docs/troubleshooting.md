# Troubleshooting

## `NuxieException(code: NOT_CONFIGURED, ...)`

Cause:

- `Nuxie.instance` used before `Nuxie.initialize(...)`.

Fix:

- Call `await Nuxie.initialize(...)` once during app startup before any SDK use.
- If using widgets, gate rendering until initialization completes.

## `triggerOnce` returns `trigger_timeout`

Cause:

- Operation did not receive a terminal update before timeout.

Fix:

- Increase timeout for slower network paths.
- Use `trigger(...)` with `updates` stream for progressive diagnostics.
- Confirm native SDK has connectivity and valid API key/environment.

## `NuxieFlowView is only supported on iOS and Android`

Cause:

- Widget rendered on unsupported target (web/desktop).

Fix:

- Use platform guards before rendering.
- Provide `placeholder` for unsupported targets.

## Android build fails due to Java version

Cause:

- Android Gradle toolchain not running on Java 17.

Fix:

- Set `JAVA_HOME` to JDK 17.
- Verify with `java -version`.

## Android plugin compile fails due to SDK/Flutter paths

Cause:

- Missing or incorrect `local.properties` for standalone module validation.

Fix:

- Ensure `packages/nuxie_flutter_native/android/local.properties` contains:
  - `sdk.dir=/absolute/path/to/android/sdk`
  - `flutter.sdk=/absolute/path/to/flutter`

## iOS build error: `No such module 'Nuxie'`

Cause:

- Native dependency not linked in host build.

Fix:

- For CocoaPods, validate pod install and plugin podspec resolution.
- For SPM, validate package dependency resolution in Xcode.
- Rebuild from clean state after dependency graph changes.

## No feature updates received in adapter package

Cause:

- Feature id mismatch or `Nuxie.initialize` not completed before adapter use.

Fix:

- Confirm queried `featureId` exactly matches the backend feature id.
- Confirm app initializes Nuxie before creating providers/cubits.
- Call `refresh()` in Bloc or verify initial fetch in Riverpod provider.
