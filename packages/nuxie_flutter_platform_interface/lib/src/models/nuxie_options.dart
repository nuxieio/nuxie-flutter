enum NuxieEnvironment {
  production,
  staging,
  development,
  custom,
}

enum NuxieEventLinkingPolicy {
  keepSeparate,
  migrateOnIdentify,
}

enum NuxieLogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  none,
}

class NuxieOptions {
  const NuxieOptions({
    this.environment = NuxieEnvironment.production,
    this.apiEndpoint,
    this.logLevel,
    this.enableConsoleLogging,
    this.enableFileLogging,
    this.redactSensitiveData,
    this.retryCount,
    this.retryDelaySeconds,
    this.eventBatchSize,
    this.flushAt,
    this.flushIntervalSeconds,
    this.maxQueueSize,
    this.maxCacheSizeBytes,
    this.cacheExpirationSeconds,
    this.featureCacheTtlSeconds,
    this.localeIdentifier,
    this.isDebugMode,
    this.eventLinkingPolicy,
    this.maxFlowCacheSizeBytes,
    this.flowCacheExpirationSeconds,
    this.maxConcurrentFlowDownloads,
    this.flowDownloadTimeoutSeconds,
    this.purchaseTimeoutSeconds,
  });

  final NuxieEnvironment environment;
  final String? apiEndpoint;
  final NuxieLogLevel? logLevel;
  final bool? enableConsoleLogging;
  final bool? enableFileLogging;
  final bool? redactSensitiveData;
  final int? retryCount;
  final int? retryDelaySeconds;
  final int? eventBatchSize;
  final int? flushAt;
  final int? flushIntervalSeconds;
  final int? maxQueueSize;
  final int? maxCacheSizeBytes;
  final int? cacheExpirationSeconds;
  final int? featureCacheTtlSeconds;
  final String? localeIdentifier;
  final bool? isDebugMode;
  final NuxieEventLinkingPolicy? eventLinkingPolicy;
  final int? maxFlowCacheSizeBytes;
  final int? flowCacheExpirationSeconds;
  final int? maxConcurrentFlowDownloads;
  final int? flowDownloadTimeoutSeconds;
  final int? purchaseTimeoutSeconds;
}
