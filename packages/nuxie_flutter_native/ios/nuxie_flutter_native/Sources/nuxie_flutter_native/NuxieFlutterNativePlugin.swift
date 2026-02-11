import Flutter
import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(Nuxie)
import Nuxie
#endif

public final class NuxieFlutterNativePlugin: NSObject, FlutterPlugin, PNuxieHostApi {
  private let flutterApi: PNuxieFlutterApi

#if canImport(Nuxie)
  private let runtime = NativeRuntime()
#endif

  private static let flowViewType = "io.nuxie.flutter.native/flow_view"

  init(binaryMessenger: FlutterBinaryMessenger) {
    flutterApi = PNuxieFlutterApi(binaryMessenger: binaryMessenger)
    super.init()
#if canImport(Nuxie)
    runtime.flutterApi = flutterApi
#endif
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = NuxieFlutterNativePlugin(binaryMessenger: registrar.messenger())
    PNuxieHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)

#if canImport(Nuxie) && canImport(UIKit)
    registrar.register(
      NuxieFlowViewFactory(runtime: instance.runtime),
      withId: flowViewType
    )
#endif
  }

  public func configure(request: PConfigureRequest, completion: @escaping (Result<Void, Error>) -> Void) {
#if canImport(Nuxie)
    guard let apiKey = request.apiKey, !apiKey.isEmpty else {
      completion(.failure(PigeonError(code: "MISSING_API_KEY", message: "apiKey is required", details: nil)))
      return
    }

    do {
      let configuration = try runtime.buildConfiguration(apiKey: apiKey, request: request)
      try NuxieSDK.shared.setup(with: configuration)
      NuxieSDK.shared.delegate = runtime
      completion(.success(()))
    } catch {
      completion(.failure(PigeonError(code: "NATIVE_ERROR", message: error.localizedDescription, details: nil)))
    }
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }

  public func shutdown(completion: @escaping (Result<Void, Error>) -> Void) {
#if canImport(Nuxie)
    Task {
      await NuxieSDK.shared.shutdown()
      runtime.cleanupPendingRequests()
      completion(.success(()))
    }
#else
    completion(.success(()))
#endif
  }

  public func identify(
    distinctId: String,
    userProperties: [String?: Any?]?,
    userPropertiesSetOnce: [String?: Any?]?,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
#if canImport(Nuxie)
    NuxieSDK.shared.identify(
      distinctId,
      userProperties: userProperties?.toStringKeyMap(),
      userPropertiesSetOnce: userPropertiesSetOnce?.toStringKeyMap()
    )
    completion(.success(()))
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }

  public func reset(keepAnonymousId: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
#if canImport(Nuxie)
    NuxieSDK.shared.reset(keepAnonymousId: keepAnonymousId)
    completion(.success(()))
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }

  public func getDistinctId(completion: @escaping (Result<String, Error>) -> Void) {
#if canImport(Nuxie)
    completion(.success(NuxieSDK.shared.getDistinctId()))
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }

  public func getAnonymousId(completion: @escaping (Result<String, Error>) -> Void) {
#if canImport(Nuxie)
    completion(.success(NuxieSDK.shared.getAnonymousId()))
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }

  public func getIsIdentified(completion: @escaping (Result<Bool, Error>) -> Void) {
#if canImport(Nuxie)
    completion(.success(NuxieSDK.shared.isIdentified))
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }

  public func startTrigger(request: PTriggerRequest, completion: @escaping (Result<Void, Error>) -> Void) {
#if canImport(Nuxie)
    guard let requestId = request.requestId, !requestId.isEmpty else {
      completion(.failure(PigeonError(code: "INVALID_TRIGGER", message: "requestId is required", details: nil)))
      return
    }
    guard let event = request.event, !event.isEmpty else {
      completion(.failure(PigeonError(code: "INVALID_TRIGGER", message: "event is required", details: nil)))
      return
    }

    let handle = NuxieSDK.shared.trigger(
      event,
      properties: request.properties?.toStringKeyMap(),
      userProperties: request.userProperties?.toStringKeyMap(),
      userPropertiesSetOnce: request.userPropertiesSetOnce?.toStringKeyMap()
    ) { [weak runtime] update in
      runtime?.sendTriggerUpdate(requestId: requestId, update: update)
    }

    runtime.triggerHandles[requestId] = handle
    completion(.success(()))
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }

  public func cancelTrigger(requestId: String, completion: @escaping (Result<Void, Error>) -> Void) {
#if canImport(Nuxie)
    runtime.triggerHandles.removeValue(forKey: requestId)?.cancel()
    completion(.success(()))
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }

  public func showFlow(flowId: String, completion: @escaping (Result<Void, Error>) -> Void) {
#if canImport(Nuxie)
    Task { @MainActor in
      do {
        try await NuxieSDK.shared.showFlow(with: flowId)
        completion(.success(()))
      } catch {
        completion(.failure(PigeonError(code: "NATIVE_ERROR", message: error.localizedDescription, details: nil)))
      }
    }
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }

  public func refreshProfile(completion: @escaping (Result<PProfileResponse, Error>) -> Void) {
#if canImport(Nuxie)
    Task {
      do {
        let profile = try await NuxieSDK.shared.refreshProfile()
        completion(.success(runtime.profileToPigeon(profile)))
      } catch {
        completion(.failure(PigeonError(code: "NATIVE_ERROR", message: error.localizedDescription, details: nil)))
      }
    }
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }

  public func hasFeature(
    featureId: String,
    requiredBalance: Int64?,
    entityId: String?,
    completion: @escaping (Result<PFeatureAccess, Error>) -> Void
  ) {
#if canImport(Nuxie)
    Task {
      do {
        let access: FeatureAccess
        if let requiredBalance {
          access = try await NuxieSDK.shared.hasFeature(
            featureId,
            requiredBalance: Int(requiredBalance),
            entityId: entityId
          )
        } else {
          access = try await NuxieSDK.shared.hasFeature(featureId)
        }
        completion(.success(runtime.featureAccessToPigeon(access)))
      } catch {
        completion(.failure(PigeonError(code: "NATIVE_ERROR", message: error.localizedDescription, details: nil)))
      }
    }
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }

  public func getCachedFeature(
    featureId: String,
    entityId: String?,
    completion: @escaping (Result<PFeatureAccess?, Error>) -> Void
  ) {
#if canImport(Nuxie)
    Task {
      let access = await NuxieSDK.shared.getCachedFeature(featureId, entityId: entityId)
      completion(.success(access.map(runtime.featureAccessToPigeon)))
    }
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }

  public func checkFeature(
    featureId: String,
    requiredBalance: Int64?,
    entityId: String?,
    completion: @escaping (Result<PFeatureCheckResult, Error>) -> Void
  ) {
#if canImport(Nuxie)
    Task {
      do {
        let result = try await NuxieSDK.shared.checkFeature(
          featureId,
          requiredBalance: requiredBalance.map(Int.init),
          entityId: entityId
        )
        completion(.success(runtime.featureCheckToPigeon(result)))
      } catch {
        completion(.failure(PigeonError(code: "NATIVE_ERROR", message: error.localizedDescription, details: nil)))
      }
    }
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }

  public func refreshFeature(
    featureId: String,
    requiredBalance: Int64?,
    entityId: String?,
    completion: @escaping (Result<PFeatureCheckResult, Error>) -> Void
  ) {
#if canImport(Nuxie)
    Task {
      do {
        let result = try await NuxieSDK.shared.refreshFeature(
          featureId,
          requiredBalance: requiredBalance.map(Int.init),
          entityId: entityId
        )
        completion(.success(runtime.featureCheckToPigeon(result)))
      } catch {
        completion(.failure(PigeonError(code: "NATIVE_ERROR", message: error.localizedDescription, details: nil)))
      }
    }
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }

  public func useFeature(
    featureId: String,
    amount: Double,
    entityId: String?,
    metadata: [String?: Any?]?,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
#if canImport(Nuxie)
    NuxieSDK.shared.useFeature(
      featureId,
      amount: amount,
      entityId: entityId,
      metadata: metadata?.toStringKeyMap()
    )
    completion(.success(()))
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }

  public func useFeatureAndWait(
    featureId: String,
    amount: Double,
    entityId: String?,
    setUsage: Bool,
    metadata: [String?: Any?]?,
    completion: @escaping (Result<PFeatureUsageResult, Error>) -> Void
  ) {
#if canImport(Nuxie)
    Task {
      do {
        let result = try await NuxieSDK.shared.useFeatureAndWait(
          featureId,
          amount: amount,
          entityId: entityId,
          setUsage: setUsage,
          metadata: metadata?.toStringKeyMap()
        )
        completion(.success(runtime.featureUsageToPigeon(result)))
      } catch {
        completion(.failure(PigeonError(code: "NATIVE_ERROR", message: error.localizedDescription, details: nil)))
      }
    }
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }

  public func flushEvents(completion: @escaping (Result<Bool, Error>) -> Void) {
#if canImport(Nuxie)
    Task {
      let didFlush = await NuxieSDK.shared.flushEvents()
      completion(.success(didFlush))
    }
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }

  public func getQueuedEventCount(completion: @escaping (Result<Int64, Error>) -> Void) {
#if canImport(Nuxie)
    Task {
      let count = await NuxieSDK.shared.getQueuedEventCount()
      completion(.success(Int64(count)))
    }
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }

  public func pauseEventQueue(completion: @escaping (Result<Void, Error>) -> Void) {
#if canImport(Nuxie)
    Task {
      await NuxieSDK.shared.pauseEventQueue()
      completion(.success(()))
    }
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }

  public func resumeEventQueue(completion: @escaping (Result<Void, Error>) -> Void) {
#if canImport(Nuxie)
    Task {
      await NuxieSDK.shared.resumeEventQueue()
      completion(.success(()))
    }
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }

  public func completePurchase(
    requestId: String,
    result: PPurchaseResult,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
#if canImport(Nuxie)
    guard runtime.resumePurchase(requestId: requestId, result: result) else {
      completion(.failure(PigeonError(code: "PURCHASE_REQUEST_NOT_FOUND", message: "No pending purchase request for \(requestId)", details: nil)))
      return
    }
    completion(.success(()))
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }

  public func completeRestore(
    requestId: String,
    result: PRestoreResult,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
#if canImport(Nuxie)
    guard runtime.resumeRestore(requestId: requestId, result: result) else {
      completion(.failure(PigeonError(code: "RESTORE_REQUEST_NOT_FOUND", message: "No pending restore request for \(requestId)", details: nil)))
      return
    }
    completion(.success(()))
#else
    completion(.failure(PigeonError(code: "NATIVE_SDK_UNAVAILABLE", message: "Nuxie iOS SDK is not linked", details: nil)))
#endif
  }
}

#if canImport(Nuxie)

private final class NativeRuntime: NSObject {
  var flutterApi: PNuxieFlutterApi?
  var triggerHandles: [String: TriggerHandle] = [:]

  private var purchaseTimeoutSeconds: Int64 = 60
  private let syncQueue = DispatchQueue(label: "io.nuxie.flutter.native.runtime")
  private var pendingPurchase: [String: CheckedContinuation<PPurchaseResult, Never>] = [:]
  private var pendingRestore: [String: CheckedContinuation<PRestoreResult, Never>] = [:]
  private var requestCounter: Int64 = 0

  func buildConfiguration(apiKey: String, request: PConfigureRequest) throws -> NuxieConfiguration {
    let configuration = NuxieConfiguration(apiKey: apiKey)

    if let environment = request.environment {
      configuration.environment = environment.toEnvironment()
    }
    if let endpoint = request.apiEndpoint, !endpoint.isEmpty, let url = URL(string: endpoint) {
      configuration.apiEndpoint = url
    }

    if let logLevel = request.logLevel {
      configuration.logLevel = logLevel.toLogLevel()
    }
    if let enableConsoleLogging = request.enableConsoleLogging {
      configuration.enableConsoleLogging = enableConsoleLogging
    }
    if let enableFileLogging = request.enableFileLogging {
      configuration.enableFileLogging = enableFileLogging
    }
    if let redactSensitiveData = request.redactSensitiveData {
      configuration.redactSensitiveData = redactSensitiveData
    }

    if let retryCount = request.retryCount {
      configuration.retryCount = Int(retryCount)
    }
    if let retryDelaySeconds = request.retryDelaySeconds {
      configuration.retryDelay = TimeInterval(retryDelaySeconds)
    }
    if let eventBatchSize = request.eventBatchSize {
      configuration.eventBatchSize = Int(eventBatchSize)
    }
    if let flushAt = request.flushAt {
      configuration.flushAt = Int(flushAt)
    }
    if let flushIntervalSeconds = request.flushIntervalSeconds {
      configuration.flushInterval = TimeInterval(flushIntervalSeconds)
    }
    if let maxQueueSize = request.maxQueueSize {
      configuration.maxQueueSize = Int(maxQueueSize)
    }

    if let maxCacheSizeBytes = request.maxCacheSizeBytes {
      configuration.maxCacheSize = Int64(maxCacheSizeBytes)
    }
    if let cacheExpirationSeconds = request.cacheExpirationSeconds {
      configuration.cacheExpiration = TimeInterval(cacheExpirationSeconds)
    }
    if let featureCacheTtlSeconds = request.featureCacheTtlSeconds {
      configuration.featureCacheTTL = TimeInterval(featureCacheTtlSeconds)
    }
    if let localeIdentifier = request.localeIdentifier {
      configuration.localeIdentifier = localeIdentifier
    }
    if let isDebugMode = request.isDebugMode {
      configuration.isDebugMode = isDebugMode
    }
    if let eventLinkingPolicy = request.eventLinkingPolicy {
      configuration.eventLinkingPolicy = eventLinkingPolicy.toEventLinkingPolicy()
    }

    if let maxFlowCacheSizeBytes = request.maxFlowCacheSizeBytes {
      configuration.maxFlowCacheSize = Int64(maxFlowCacheSizeBytes)
    }
    if let flowCacheExpirationSeconds = request.flowCacheExpirationSeconds {
      configuration.flowCacheExpiration = TimeInterval(flowCacheExpirationSeconds)
    }
    if let maxConcurrentFlowDownloads = request.maxConcurrentFlowDownloads {
      configuration.maxConcurrentFlowDownloads = Int(maxConcurrentFlowDownloads)
    }
    if let flowDownloadTimeoutSeconds = request.flowDownloadTimeoutSeconds {
      configuration.flowDownloadTimeout = TimeInterval(flowDownloadTimeoutSeconds)
    }

    purchaseTimeoutSeconds = request.purchaseTimeoutSeconds ?? 60

    if request.usingPurchaseController == true {
      configuration.purchaseDelegate = FlutterPurchaseDelegate(runtime: self)
    }

    return configuration
  }

  func sendTriggerUpdate(requestId: String, update: TriggerUpdate) {
    guard let flutterApi else { return }
    flutterApi.onTriggerUpdate(event: triggerUpdateToPigeon(requestId: requestId, update: update)) { _ in }
  }

  func profileToPigeon(_ profile: ProfileResponse) -> PProfileResponse {
    let encoder = JSONEncoder()
    if let data = try? encoder.encode(profile),
      let value = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    {
      return PProfileResponse(raw: value.bridgeDictionary())
    }
    return PProfileResponse(raw: [:])
  }

  func featureAccessToPigeon(_ access: FeatureAccess) -> PFeatureAccess {
    return PFeatureAccess(
      allowed: access.allowed,
      unlimited: access.unlimited,
      balance: access.balance.map(Int64.init),
      type: access.type.toBridgeType()
    )
  }

  func featureCheckToPigeon(_ result: FeatureCheckResult) -> PFeatureCheckResult {
    return PFeatureCheckResult(
      customerId: result.customerId,
      featureId: result.featureId,
      requiredBalance: Int64(result.requiredBalance),
      code: result.code,
      allowed: result.allowed,
      unlimited: result.unlimited,
      balance: result.balance.map(Int64.init),
      type: result.type.toBridgeType(),
      preview: result.preview?.value
    )
  }

  func featureUsageToPigeon(_ result: FeatureUsageResult) -> PFeatureUsageResult {
    return PFeatureUsageResult(
      success: result.success,
      featureId: result.featureId,
      amountUsed: result.amountUsed,
      message: result.message,
      usageCurrent: result.usage?.current,
      usageLimit: result.usage?.limit,
      usageRemaining: result.usage?.remaining
    )
  }

  func awaitPurchaseResult(request: PPurchaseRequest) async -> PPurchaseResult {
    guard let requestId = request.requestId else {
      return PPurchaseResult(type: "failed", message: "invalid_purchase_request")
    }

    guard let flutterApi else {
      return PPurchaseResult(type: "failed", message: "flutter_api_unavailable")
    }

    return await withCheckedContinuation { continuation in
      syncQueue.async {
        self.pendingPurchase[requestId] = continuation
      }

      flutterApi.onPurchaseRequest(request: request) { _ in }

      Task {
        try? await Task.sleep(nanoseconds: UInt64(self.purchaseTimeoutSeconds) * 1_000_000_000)
        self.syncQueue.async {
          if let pending = self.pendingPurchase.removeValue(forKey: requestId) {
            pending.resume(returning: PPurchaseResult(type: "failed", message: "purchase_timeout"))
          }
        }
      }
    }
  }

  func awaitRestoreResult(request: PRestoreRequest) async -> PRestoreResult {
    guard let requestId = request.requestId else {
      return PRestoreResult(type: "failed", message: "invalid_restore_request")
    }

    guard let flutterApi else {
      return PRestoreResult(type: "failed", message: "flutter_api_unavailable")
    }

    return await withCheckedContinuation { continuation in
      syncQueue.async {
        self.pendingRestore[requestId] = continuation
      }

      flutterApi.onRestoreRequest(request: request) { _ in }

      Task {
        try? await Task.sleep(nanoseconds: UInt64(self.purchaseTimeoutSeconds) * 1_000_000_000)
        self.syncQueue.async {
          if let pending = self.pendingRestore.removeValue(forKey: requestId) {
            pending.resume(returning: PRestoreResult(type: "failed", message: "restore_timeout"))
          }
        }
      }
    }
  }

  func resumePurchase(requestId: String, result: PPurchaseResult) -> Bool {
    var continuation: CheckedContinuation<PPurchaseResult, Never>?
    syncQueue.sync {
      continuation = pendingPurchase.removeValue(forKey: requestId)
    }
    continuation?.resume(returning: result)
    return continuation != nil
  }

  func resumeRestore(requestId: String, result: PRestoreResult) -> Bool {
    var continuation: CheckedContinuation<PRestoreResult, Never>?
    syncQueue.sync {
      continuation = pendingRestore.removeValue(forKey: requestId)
    }
    continuation?.resume(returning: result)
    return continuation != nil
  }

  func cleanupPendingRequests() {
    syncQueue.sync {
      for (_, continuation) in pendingPurchase {
        continuation.resume(returning: PPurchaseResult(type: "failed", message: "sdk_shutdown"))
      }
      pendingPurchase.removeAll()

      for (_, continuation) in pendingRestore {
        continuation.resume(returning: PRestoreResult(type: "failed", message: "sdk_shutdown"))
      }
      pendingRestore.removeAll()
    }
  }

  func nextRequestId(prefix: String) -> String {
    syncQueue.sync {
      requestCounter += 1
      return "\(prefix)-\(Date().timeIntervalSince1970)-\(requestCounter)-\(UUID().uuidString)"
    }
  }
}

extension NativeRuntime: NuxieDelegate {
  func featureAccessDidChange(_ featureId: String, from oldValue: FeatureAccess?, to newValue: FeatureAccess) {
    guard let flutterApi else { return }
    flutterApi.onFeatureAccessChanged(
      event: PFeatureAccessChangedEvent(
        featureId: featureId,
        from: oldValue.map(featureAccessToPigeon),
        to: featureAccessToPigeon(newValue),
        timestampMs: Int64(Date().timeIntervalSince1970 * 1000)
      )
    ) { _ in }
  }
}

private final class FlutterPurchaseDelegate: NuxiePurchaseDelegate {
  private weak var runtime: NativeRuntime?

  init(runtime: NativeRuntime) {
    self.runtime = runtime
  }

  func purchase(_ product: any StoreProductProtocol) async -> PurchaseResult {
    return await purchaseOutcome(product).result
  }

  func purchaseOutcome(_ product: any StoreProductProtocol) async -> PurchaseOutcome {
    guard let runtime else {
      return PurchaseOutcome(result: .failed(PigeonError(code: "purchase_delegate_missing", message: "Runtime unavailable", details: nil)))
    }

    let requestId = runtime.nextRequestId(prefix: "purchase")
    let request = PPurchaseRequest(
      requestId: requestId,
      platform: "ios",
      productId: product.id,
      displayName: product.displayName,
      displayPrice: product.displayPrice,
      price: NSDecimalNumber(decimal: product.price).doubleValue,
      timestampMs: Int64(Date().timeIntervalSince1970 * 1000)
    )

    let response = await runtime.awaitPurchaseResult(request: request)
    return response.toPurchaseOutcome(defaultProductId: product.id)
  }

  func restore() async -> RestoreResult {
    guard let runtime else {
      return .failed(PigeonError(code: "restore_delegate_missing", message: "Runtime unavailable", details: nil))
    }

    let requestId = runtime.nextRequestId(prefix: "restore")
    let request = PRestoreRequest(
      requestId: requestId,
      platform: "ios",
      timestampMs: Int64(Date().timeIntervalSince1970 * 1000)
    )
    let response = await runtime.awaitRestoreResult(request: request)
    return response.toRestoreResult()
  }
}

#if canImport(UIKit)

private final class NuxieFlowViewFactory: NSObject, FlutterPlatformViewFactory {
  private let runtime: NativeRuntime

  init(runtime: NativeRuntime) {
    self.runtime = runtime
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    let flowId = (args as? [String: Any])?["flowId"] as? String
    return NuxieFlowPlatformView(frame: frame, flowId: flowId)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

private final class NuxieFlowPlatformView: NSObject, FlutterPlatformView {
  private let container: UIView

  init(frame: CGRect, flowId: String?) {
    container = UIView(frame: frame)
    super.init()

    guard let flowId, !flowId.isEmpty else { return }

    Task { @MainActor in
      do {
        let controller = try await NuxieSDK.shared.getFlowViewController(with: flowId)
        controller.view.frame = container.bounds
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(controller.view)
      } catch {
        // Leave empty container when flow embed fails.
      }
    }
  }

  func view() -> UIView {
    container
  }
}

#endif

private extension PPurchaseResult {
  func toPurchaseOutcome(defaultProductId: String) -> PurchaseOutcome {
    let resultType = (type ?? "failed").lowercased()
    switch resultType {
    case "success":
      return PurchaseOutcome(
        result: .success,
        transactionJws: transactionJws,
        transactionId: transactionId,
        originalTransactionId: originalTransactionId,
        productId: productId ?? defaultProductId
      )
    case "cancelled":
      return PurchaseOutcome(result: .cancelled, productId: productId ?? defaultProductId)
    case "pending":
      return PurchaseOutcome(result: .pending, productId: productId ?? defaultProductId)
    default:
      let message = self.message ?? "purchase_failed"
      return PurchaseOutcome(
        result: .failed(PigeonError(code: "purchase_failed", message: message, details: nil)),
        productId: productId ?? defaultProductId
      )
    }
  }
}

private extension PRestoreResult {
  func toRestoreResult() -> RestoreResult {
    let resultType = (type ?? "failed").lowercased()
    switch resultType {
    case "success":
      return .success(restoredCount: Int(restoredCount ?? 0))
    case "no_purchases":
      return .noPurchases
    default:
      return .failed(PigeonError(code: "restore_failed", message: message ?? "restore_failed", details: nil))
    }
  }
}

private extension TriggerUpdate {
  func toPigeon(requestId: String) -> PTriggerUpdate {
    switch self {
    case .decision(let decision):
      return PTriggerUpdate(
        requestId: requestId,
        updateKind: "decision",
        payload: decision.toPayload(),
        isTerminal: decision.isTerminal,
        timestampMs: Int64(Date().timeIntervalSince1970 * 1000)
      )
    case .entitlement(let entitlement):
      return PTriggerUpdate(
        requestId: requestId,
        updateKind: "entitlement",
        payload: entitlement.toPayload(),
        isTerminal: entitlement.isTerminal,
        timestampMs: Int64(Date().timeIntervalSince1970 * 1000)
      )
    case .journey(let journey):
      return PTriggerUpdate(
        requestId: requestId,
        updateKind: "journey",
        payload: journey.toPayload(),
        isTerminal: true,
        timestampMs: Int64(Date().timeIntervalSince1970 * 1000)
      )
    case .error(let error):
      return PTriggerUpdate(
        requestId: requestId,
        updateKind: "error",
        payload: [
          "code": error.code,
          "message": error.message,
        ],
        isTerminal: true,
        timestampMs: Int64(Date().timeIntervalSince1970 * 1000)
      )
    }
  }
}

private extension NativeRuntime {
  func triggerUpdateToPigeon(requestId: String, update: TriggerUpdate) -> PTriggerUpdate {
    return update.toPigeon(requestId: requestId)
  }
}

private extension TriggerDecision {
  var isTerminal: Bool {
    switch self {
    case .allowedImmediate, .deniedImmediate, .noMatch, .suppressed:
      return true
    case .flowShown, .journeyResumed, .journeyStarted:
      return false
    }
  }

  func toPayload() -> [String: Any?] {
    switch self {
    case .noMatch:
      return ["type": "no_match"]
    case .suppressed(let reason):
      return [
        "type": "suppressed",
        "reason": reason.toBridgeReason(),
      ]
    case .journeyStarted(let ref):
      return [
        "type": "journey_started",
        "ref": ref.toBridgeRef(),
      ]
    case .journeyResumed(let ref):
      return [
        "type": "journey_resumed",
        "ref": ref.toBridgeRef(),
      ]
    case .flowShown(let ref):
      return [
        "type": "flow_shown",
        "ref": ref.toBridgeRef(),
      ]
    case .allowedImmediate:
      return ["type": "allowed_immediate"]
    case .deniedImmediate:
      return ["type": "denied_immediate"]
    }
  }
}

private extension EntitlementUpdate {
  var isTerminal: Bool {
    switch self {
    case .allowed, .denied:
      return true
    case .pending:
      return false
    }
  }

  func toPayload() -> [String: Any?] {
    switch self {
    case .pending:
      return ["type": "pending"]
    case .allowed(let source):
      return [
        "type": "allowed",
        "source": source.toBridgeSource(),
      ]
    case .denied:
      return ["type": "denied"]
    }
  }
}

private extension JourneyUpdate {
  func toPayload() -> [String: Any?] {
    return [
      "journeyId": journeyId,
      "campaignId": campaignId,
      "flowId": flowId,
      "exitReason": exitReason.toBridgeValue(),
      "goalMet": goalMet,
      "goalMetAtEpochMillis": goalMetAt.map { Int64($0.timeIntervalSince1970 * 1000) },
      "durationSeconds": durationSeconds,
      "flowExitReason": flowExitReason,
    ]
  }
}

private extension JourneyRef {
  func toBridgeRef() -> [String: Any?] {
    [
      "journeyId": journeyId,
      "campaignId": campaignId,
      "flowId": flowId,
    ]
  }
}

private extension SuppressReason {
  func toBridgeReason() -> String {
    switch self {
    case .alreadyActive:
      return "already_active"
    case .holdout:
      return "holdout"
    case .noFlow:
      return "no_flow"
    case .reentryLimited:
      return "reentry_limited"
    case .unknown:
      return "unknown"
    }
  }
}

private extension GateSource {
  func toBridgeSource() -> String {
    switch self {
    case .cache:
      return "cache"
    case .purchase:
      return "purchase"
    case .restore:
      return "restore"
    }
  }
}

private extension JourneyExitReason {
  func toBridgeValue() -> String {
    switch self {
    case .completed:
      return "completed"
    case .goalMet:
      return "goal_met"
    case .triggerUnmatched:
      return "trigger_unmatched"
    case .expired:
      return "expired"
    case .error:
      return "error"
    case .cancelled:
      return "cancelled"
    }
  }
}

private extension FeatureType {
  func toBridgeType() -> String {
    switch self {
    case .boolean:
      return "boolean"
    case .metered:
      return "metered"
    case .creditSystem:
      return "creditSystem"
    }
  }
}

private extension String {
  func toEnvironment() -> Environment {
    switch lowercased() {
    case "staging":
      return .staging
    case "development":
      return .development
    case "custom":
      return .custom
    default:
      return .production
    }
  }

  func toLogLevel() -> LogLevel {
    switch lowercased() {
    case "verbose":
      return .verbose
    case "debug":
      return .debug
    case "info":
      return .info
    case "warning":
      return .warning
    case "error":
      return .error
    case "none":
      return .none
    default:
      return .warning
    }
  }

  func toEventLinkingPolicy() -> EventLinkingPolicy {
    switch lowercased() {
    case "keep_separate":
      return .keepSeparate
    case "migrate_on_identify":
      return .migrateOnIdentify
    default:
      return .migrateOnIdentify
    }
  }
}

private extension Dictionary where Key == String?, Value == Any? {
  func toStringKeyMap() -> [String: Any] {
    var mapped: [String: Any] = [:]
    for (key, value) in self {
      guard let key, !key.isEmpty else { continue }
      mapped[key] = value
    }
    return mapped
  }
}

private extension Dictionary where Key == String, Value == Any {
  func bridgeDictionary() -> [String?: Any?] {
    var mapped: [String?: Any?] = [:]
    for (key, value) in self {
      mapped[key] = value.bridgeValue()
    }
    return mapped
  }
}

private extension Any {
  func bridgeValue() -> Any? {
    switch self {
    case let value as String:
      return value
    case let value as NSNumber:
      return value
    case let value as Bool:
      return value
    case let value as [String: Any]:
      return value.bridgeDictionary()
    case let value as [Any]:
      return value.map { $0.bridgeValue() }
    case let value as NSNull:
      _ = value
      return nil
    default:
      return String(describing: self)
    }
  }
}

#endif
