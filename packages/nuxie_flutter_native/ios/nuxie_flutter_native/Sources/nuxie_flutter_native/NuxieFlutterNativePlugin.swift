import Foundation

#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

#if canImport(Nuxie)
import Nuxie
#endif

public final class NuxieFlutterNativePlugin: NSObject, FlutterPlugin, PNuxieHostApi {
  private let flutterApi: PNuxieFlutterApi

#if canImport(Nuxie)
  private lazy var purchaseBridge = FlutterPurchaseDelegateBridge { [weak self] request in
    guard let self else { return }
    switch request {
    case .purchase(let value):
      self.flutterApi.onPurchaseRequest(request: value) { _ in }
    case .restore(let value):
      self.flutterApi.onRestoreRequest(request: value) { _ in }
    }
  }

  @MainActor
  private lazy var delegateBridge = FlutterNuxieDelegate(flutterApi: flutterApi)
#endif

  init(binaryMessenger: FlutterBinaryMessenger) {
    flutterApi = PNuxieFlutterApi(binaryMessenger: binaryMessenger)
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let plugin = NuxieFlutterNativePlugin(binaryMessenger: registrar.messenger())
    PNuxieHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: plugin)
  }

  func configure(
    request: PConfigureRequest,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
#if canImport(Nuxie)
    guard let apiKey = request.apiKey?.trimmingCharacters(in: .whitespacesAndNewlines),
          !apiKey.isEmpty else {
      completion(.failure(bridgeError("MISSING_API_KEY", "apiKey is required")))
      return
    }

    Task { @MainActor in
      do {
        let configuration = self.configuration(apiKey: apiKey, request: request)
        NuxieSDK.shared.delegate = self.delegateBridge
        try NuxieSDK.shared.setup(with: configuration)
        completion(.success(()))
      } catch {
        completion(.failure(error))
      }
    }
#else
    completion(.failure(bridgeError("NATIVE_SDK_UNAVAILABLE", "Nuxie iOS SDK is not linked")))
#endif
  }

  func shutdown(completion: @escaping (Result<Void, Error>) -> Void) {
#if canImport(Nuxie)
    purchaseBridge.cancelPending(reason: "sdk_shutdown")
    Task {
      await NuxieSDK.shared.shutdown()
      await MainActor.run {
        NuxieSDK.shared.delegate = nil
      }
      completion(.success(()))
    }
#else
    completion(.success(()))
#endif
  }

  func identify(
    distinctId: String,
    userProperties: [String?: Any?]?,
    userPropertiesSetOnce: [String?: Any?]?,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
#if canImport(Nuxie)
    NuxieSDK.shared.identify(
      distinctId,
      userProperties: userProperties?.stringKeyed,
      userPropertiesSetOnce: userPropertiesSetOnce?.stringKeyed
    )
    completion(.success(()))
#else
    completion(.failure(bridgeError("NATIVE_SDK_UNAVAILABLE", "Nuxie iOS SDK is not linked")))
#endif
  }

  func reset(
    keepAnonymousId: Bool,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
#if canImport(Nuxie)
    NuxieSDK.shared.reset(keepAnonymousId: keepAnonymousId)
    completion(.success(()))
#else
    completion(.failure(bridgeError("NATIVE_SDK_UNAVAILABLE", "Nuxie iOS SDK is not linked")))
#endif
  }

  func getDistinctId(completion: @escaping (Result<String, Error>) -> Void) {
#if canImport(Nuxie)
    completion(.success(NuxieSDK.shared.getDistinctId()))
#else
    completion(.failure(bridgeError("NATIVE_SDK_UNAVAILABLE", "Nuxie iOS SDK is not linked")))
#endif
  }

  func getAnonymousId(completion: @escaping (Result<String, Error>) -> Void) {
#if canImport(Nuxie)
    completion(.success(NuxieSDK.shared.getAnonymousId()))
#else
    completion(.failure(bridgeError("NATIVE_SDK_UNAVAILABLE", "Nuxie iOS SDK is not linked")))
#endif
  }

  func getIsIdentified(completion: @escaping (Result<Bool, Error>) -> Void) {
#if canImport(Nuxie)
    completion(.success(NuxieSDK.shared.isIdentified))
#else
    completion(.failure(bridgeError("NATIVE_SDK_UNAVAILABLE", "Nuxie iOS SDK is not linked")))
#endif
  }

  func trigger(event: String, properties: [String?: Any?]?) throws {
#if canImport(Nuxie)
    NuxieSDK.shared.trigger(event, properties: properties?.stringKeyed)
#endif
  }

  func dismiss(completion: @escaping (Result<Void, Error>) -> Void) {
#if canImport(Nuxie)
    Task { @MainActor in
      await NuxieSDK.shared.dismiss()
      completion(.success(()))
    }
#else
    completion(.success(()))
#endif
  }

  func setLocaleIdentifier(
    localeIdentifier: String?,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
#if canImport(Nuxie)
    Task {
      do {
        try await NuxieSDK.shared.setLocaleIdentifier(localeIdentifier)
        completion(.success(()))
      } catch {
        completion(.failure(error))
      }
    }
#else
    completion(.failure(bridgeError("NATIVE_SDK_UNAVAILABLE", "Nuxie iOS SDK is not linked")))
#endif
  }

  func hasFeature(
    featureId: String,
    requiredBalance: Double,
    entityId: String?,
    policy: String,
    completion: @escaping (Result<PFeatureAccess, Error>) -> Void
  ) {
#if canImport(Nuxie)
    Task {
      do {
        let access = try await NuxieSDK.shared.hasFeature(
          featureId,
          requiredBalance: requiredBalance,
          entityId: entityId,
          policy: policy == "remote" ? .remote : .cacheFirst
        )
        completion(.success(access.pigeon))
      } catch {
        completion(.failure(error))
      }
    }
#else
    completion(.failure(bridgeError("NATIVE_SDK_UNAVAILABLE", "Nuxie iOS SDK is not linked")))
#endif
  }

  func useFeature(
    featureId: String,
    amount: Double,
    entityId: String?,
    metadata: [String?: Any?]?
  ) throws {
#if canImport(Nuxie)
    NuxieSDK.shared.useFeature(
      featureId,
      amount: amount,
      entityId: entityId,
      metadata: metadata?.stringKeyed
    )
#endif
  }

  func useFeatureAndWait(
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
          metadata: metadata?.stringKeyed
        )
        completion(.success(result.pigeon))
      } catch {
        completion(.failure(error))
      }
    }
#else
    completion(.failure(bridgeError("NATIVE_SDK_UNAVAILABLE", "Nuxie iOS SDK is not linked")))
#endif
  }

  func completePurchase(requestId: String, result: PPurchaseResult) throws {
#if canImport(Nuxie)
    purchaseBridge.completePurchase(requestId: requestId, result: result)
#endif
  }

  func completeRestore(requestId: String, result: PRestoreResult) throws {
#if canImport(Nuxie)
    purchaseBridge.completeRestore(requestId: requestId, result: result)
#endif
  }

#if canImport(Nuxie)
  @MainActor
  private func configuration(
    apiKey: String,
    request: PConfigureRequest
  ) -> NuxieConfiguration {
    let value = NuxieConfiguration(apiKey: apiKey)
    value.environment = request.environment == "development" ? .development : .production
    if let logLevel = request.logLevel {
      value.logLevel = switch logLevel {
      case "verbose": .verbose
      case "debug": .debug
      case "info": .info
      case "error": .error
      case "none": .none
      default: .warning
      }
    }
    if let enabled = request.enableConsoleLogging {
      value.enableConsoleLogging = enabled
    }
    if let redact = request.redactSensitiveData {
      value.redactSensitiveData = redact
    }
    value.localeIdentifier = request.localeIdentifier
    value.purchaseHandlingMode = request.purchaseHandlingMode == "observer" ? .observer : .full
    if let testStoreEnabled = request.testStoreEnabled {
      value.testStoreEnabled = testStoreEnabled
    }
    if request.usingPurchaseController == true {
      value.purchaseDelegate = purchaseBridge
    }
    return value
  }
#endif
}

private func bridgeError(_ code: String, _ message: String) -> PigeonError {
  PigeonError(code: code, message: message, details: nil)
}

private extension Dictionary where Key == String?, Value == Any? {
  var stringKeyed: [String: Any] {
    reduce(into: [:]) { result, entry in
      if let key = entry.key, let value = entry.value {
        result[key] = value
      }
    }
  }
}

#if canImport(Nuxie)
@MainActor
private final class FlutterNuxieDelegate: NuxieDelegate {
  private let flutterApi: PNuxieFlutterApi

  init(flutterApi: PNuxieFlutterApi) {
    self.flutterApi = flutterApi
  }

  func featureAccessDidChange(
    _ featureId: String,
    from oldValue: FeatureAccess?,
    to newValue: FeatureAccess
  ) {
    flutterApi.onFeatureAccessChanged(
      event: PFeatureAccessChangedEvent(
        featureId: featureId,
        from: oldValue?.pigeon,
        to: newValue.pigeon,
        timestampMs: Int64(Date().timeIntervalSince1970 * 1_000)
      )
    ) { _ in }
  }

  func nuxieDidEmit(_ info: NuxieActivityInfo) {
    flutterApi.onActivity(
      activity: PActivityInfo(
        schemaVersion: Int64(NuxieActivityInfo.schemaVersion),
        id: info.id,
        timestampMs: Int64(info.timestamp.timeIntervalSince1970 * 1_000),
        receivedAtMs: Int64(info.receivedAt.timeIntervalSince1970 * 1_000),
        name: info.name,
        properties: info.properties.reduce(into: [:]) { result, entry in
          result[entry.key] = entry.value.bridgeValue
        }
      )
    ) { _ in }
  }

  func nuxie(_ sdk: NuxieSDK, didRequestAppAction action: AppAction) {
    flutterApi.onAppAction(
      action: PAppAction(
        name: action.name,
        payload: action.payload?.reduce(into: [:]) { result, entry in
          result[entry.key] = entry.value.bridgeValue
        },
        experience: PExperienceRef(
          experienceId: action.experience.experienceId,
          experienceVersion: action.experience.experienceVersion,
          journeyId: action.experience.journeyId
        )
      )
    ) { _ in }
  }
}

private extension FeatureAccess {
  var pigeon: PFeatureAccess {
    PFeatureAccess(
      allowed: allowed,
      unlimited: unlimited,
      balance: balance,
      type: type.rawValue
    )
  }
}

private extension FeatureUsageResult {
  var pigeon: PFeatureUsageResult {
    PFeatureUsageResult(
      success: success,
      featureId: featureId,
      amountUsed: amountUsed,
      message: message,
      usageCurrent: usage?.current,
      usageLimit: usage?.limit,
      usageRemaining: usage?.remaining,
      authoritativeAccess: authoritativeAccess?.pigeon
    )
  }
}

private extension NuxieActivityValue {
  var bridgeValue: Any {
    switch self {
    case .string(let value): value
    case .int(let value): value
    case .double(let value): value
    case .bool(let value): value
    }
  }
}

private extension AppActionValue {
  var bridgeValue: Any {
    switch self {
    case .string(let value): value
    case .int(let value): value
    case .double(let value): value
    case .bool(let value): value
    }
  }
}

private enum FlutterCommerceRequest {
  case purchase(PPurchaseRequest)
  case restore(PRestoreRequest)
}

private final class FlutterPurchaseDelegateBridge: NuxiePurchaseDelegate, @unchecked Sendable {
  private let emit: (FlutterCommerceRequest) -> Void
  private let timeoutSeconds: TimeInterval
  private let lock = NSLock()
  private var purchases: [String: CheckedContinuation<PurchaseResult, Never>] = [:]
  private var restores: [String: CheckedContinuation<RestoreResult, Never>] = [:]

  init(
    timeoutSeconds: TimeInterval = 60,
    emit: @escaping (FlutterCommerceRequest) -> Void
  ) {
    self.timeoutSeconds = timeoutSeconds
    self.emit = emit
  }

  func purchase(product: StoreProduct) async -> PurchaseResult {
    let requestId = UUID().uuidString
    let request = PPurchaseRequest(
      requestId: requestId,
      platform: "ios",
      productId: product.productId,
      storeProductId: product.storeProductId,
      basePlanId: nil,
      purchaseOptionId: nil,
      offerId: nil,
      placementId: product.placementId,
      displayName: product.name,
      displayPrice: product.price,
      timestampMs: Int64(Date().timeIntervalSince1970 * 1_000)
    )
    return await withCheckedContinuation { continuation in
      lock.withLock { purchases[requestId] = continuation }
      emit(.purchase(request))
      schedulePurchaseTimeout(requestId)
    }
  }

  func restorePurchases() async -> RestoreResult {
    let requestId = UUID().uuidString
    let request = PRestoreRequest(
      requestId: requestId,
      platform: "ios",
      timestampMs: Int64(Date().timeIntervalSince1970 * 1_000)
    )
    return await withCheckedContinuation { continuation in
      lock.withLock { restores[requestId] = continuation }
      emit(.restore(request))
      scheduleRestoreTimeout(requestId)
    }
  }

  func completePurchase(requestId: String, result: PPurchaseResult) {
    let continuation = lock.withLock { purchases.removeValue(forKey: requestId) }
    let outcome: PurchaseResult = switch result.type?.lowercased() {
    case "purchased": .purchased
    case "cancelled": .cancelled
    case "pending": .pending
    default: .failed(error(result.message ?? "purchase_failed"))
    }
    continuation?.resume(returning: outcome)
  }

  func completeRestore(requestId: String, result: PRestoreResult) {
    let continuation = lock.withLock { restores.removeValue(forKey: requestId) }
    let outcome: RestoreResult = switch result.type?.lowercased() {
    case "restored": .restored
    case "no_purchases": .noPurchases
    default: .failed(error(result.message ?? "restore_failed"))
    }
    continuation?.resume(returning: outcome)
  }

  func cancelPending(reason: String) {
    let pending = lock.withLock {
      let pending = (Array(purchases.values), Array(restores.values))
      purchases.removeAll()
      restores.removeAll()
      return pending
    }
    pending.0.forEach { $0.resume(returning: .failed(error(reason))) }
    pending.1.forEach { $0.resume(returning: .failed(error(reason))) }
  }

  private func schedulePurchaseTimeout(_ requestId: String) {
    Task { [weak self] in
      guard let self else { return }
      try? await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
      let continuation = self.lock.withLock { self.purchases.removeValue(forKey: requestId) }
      continuation?.resume(returning: .failed(self.error("purchase_timeout")))
    }
  }

  private func scheduleRestoreTimeout(_ requestId: String) {
    Task { [weak self] in
      guard let self else { return }
      try? await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
      let continuation = self.lock.withLock { self.restores.removeValue(forKey: requestId) }
      continuation?.resume(returning: .failed(self.error("restore_timeout")))
    }
  }

  private func error(_ message: String) -> Error {
    NSError(
      domain: "io.nuxie.flutter",
      code: 1,
      userInfo: [NSLocalizedDescriptionKey: message]
    )
  }
}
#endif
