enum NuxieEnvironment { production, development }

enum NuxieLogLevel { verbose, debug, info, warning, error, none }

enum PurchaseHandlingMode { full, observer }

/// Customer-owned setup values shared by the native SDKs.
class NuxieOptions {
  const NuxieOptions({
    this.environment = NuxieEnvironment.production,
    this.logLevel,
    this.enableConsoleLogging,
    this.redactSensitiveData,
    this.localeIdentifier,
    this.purchaseHandlingMode,
    this.testStoreEnabled,
  });

  final NuxieEnvironment environment;
  final NuxieLogLevel? logLevel;
  final bool? enableConsoleLogging;
  final bool? redactSensitiveData;
  final String? localeIdentifier;
  final PurchaseHandlingMode? purchaseHandlingMode;

  /// iOS development builds only. Ignored on Android.
  final bool? testStoreEnabled;
}
