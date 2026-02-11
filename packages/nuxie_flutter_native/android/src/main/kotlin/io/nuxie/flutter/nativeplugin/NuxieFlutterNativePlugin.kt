package io.nuxie.flutter.nativeplugin

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.FrameLayout
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec
import io.nuxie.sdk.NuxieDelegate
import io.nuxie.sdk.NuxieSDK
import io.nuxie.sdk.config.Environment
import io.nuxie.sdk.config.EventLinkingPolicy
import io.nuxie.sdk.config.LogLevel
import io.nuxie.sdk.config.NuxieConfiguration
import io.nuxie.sdk.features.FeatureAccess
import io.nuxie.sdk.features.FeatureCheckResult
import io.nuxie.sdk.features.FeatureType
import io.nuxie.sdk.features.FeatureUsageResult
import io.nuxie.sdk.network.models.ProfileResponse
import io.nuxie.sdk.purchases.NuxiePurchaseDelegate
import io.nuxie.sdk.purchases.PurchaseOutcome
import io.nuxie.sdk.purchases.PurchaseResult
import io.nuxie.sdk.purchases.RestoreResult
import io.nuxie.sdk.triggers.EntitlementUpdate
import io.nuxie.sdk.triggers.GateSource
import io.nuxie.sdk.triggers.JourneyExitReason
import io.nuxie.sdk.triggers.JourneyRef
import io.nuxie.sdk.triggers.JourneyUpdate
import io.nuxie.sdk.triggers.SuppressReason
import io.nuxie.sdk.triggers.TriggerDecision
import io.nuxie.sdk.triggers.TriggerError
import io.nuxie.sdk.triggers.TriggerHandle
import io.nuxie.sdk.triggers.TriggerUpdate
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicLong
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

class NuxieFlutterNativePlugin :
  FlutterPlugin,
  ActivityAware,
  PNuxieHostApi,
  NuxieDelegate {

  companion object {
    private const val FLOW_VIEW_TYPE = "io.nuxie.flutter.native/flow_view"
  }

  private val sdk: NuxieSDK = NuxieSDK.shared()
  private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
  private val json = Json {
    ignoreUnknownKeys = true
    explicitNulls = false
  }

  private lateinit var applicationContext: Context
  private var activity: Activity? = null
  private var flutterApi: PNuxieFlutterApi? = null

  private var purchaseTimeoutMs: Long = 60_000L

  private val triggerHandles = ConcurrentHashMap<String, TriggerHandle>()
  private val pendingPurchases = ConcurrentHashMap<String, CompletableDeferred<PPurchaseResult>>()
  private val pendingRestores = ConcurrentHashMap<String, CompletableDeferred<PRestoreResult>>()
  private val requestCounter = AtomicLong(0)

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = binding.applicationContext
    flutterApi = PNuxieFlutterApi(binding.binaryMessenger)
    PNuxieHostApi.setUp(binding.binaryMessenger, this)
    binding.platformViewRegistry.registerViewFactory(
      FLOW_VIEW_TYPE,
      NuxieFlowViewFactory(this),
    )
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    PNuxieHostApi.setUp(binding.binaryMessenger, null)
    flutterApi = null
    cleanupPendingRequests()
    scope.cancel()
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun configure(request: PConfigureRequest, callback: (Result<Unit>) -> Unit) {
    val apiKey = request.apiKey
    if (apiKey.isNullOrBlank()) {
      callback(Result.failure(FlutterError("MISSING_API_KEY", "apiKey is required", null)))
      return
    }

    scope.launch {
      runCatching {
        val configuration = buildConfiguration(apiKey, request)
        if (request.usingPurchaseController == true) {
          configuration.purchaseDelegate = FlutterPurchaseDelegate(this@NuxieFlutterNativePlugin)
        }

        sdk.setup(applicationContext, configuration)
        sdk.delegate = this@NuxieFlutterNativePlugin
      }.onSuccess {
        callback(Result.success(Unit))
      }.onFailure { error ->
        callback(Result.failure(toFlutterError(error)))
      }
    }
  }

  override fun shutdown(callback: (Result<Unit>) -> Unit) {
    scope.launch {
      runCatching {
        cleanupPendingRequests()
        sdk.shutdown()
      }.onSuccess {
        callback(Result.success(Unit))
      }.onFailure { error ->
        callback(Result.failure(toFlutterError(error)))
      }
    }
  }

  override fun identify(
    distinctId: String,
    userProperties: Map<String?, Any?>?,
    userPropertiesSetOnce: Map<String?, Any?>?,
    callback: (Result<Unit>) -> Unit,
  ) {
    runCatching {
      sdk.identify(
        distinctId,
        userProperties = userProperties.toStringKeyMap(),
        userPropertiesSetOnce = userPropertiesSetOnce.toStringKeyMap(),
      )
      callback(Result.success(Unit))
    }.onFailure { error ->
      callback(Result.failure(toFlutterError(error)))
    }
  }

  override fun reset(keepAnonymousId: Boolean, callback: (Result<Unit>) -> Unit) {
    runCatching {
      sdk.reset(keepAnonymousId)
      callback(Result.success(Unit))
    }.onFailure { error ->
      callback(Result.failure(toFlutterError(error)))
    }
  }

  override fun getDistinctId(callback: (Result<String>) -> Unit) {
    runCatching {
      callback(Result.success(sdk.getDistinctId()))
    }.onFailure { error ->
      callback(Result.failure(toFlutterError(error)))
    }
  }

  override fun getAnonymousId(callback: (Result<String>) -> Unit) {
    runCatching {
      callback(Result.success(sdk.getAnonymousId()))
    }.onFailure { error ->
      callback(Result.failure(toFlutterError(error)))
    }
  }

  override fun getIsIdentified(callback: (Result<Boolean>) -> Unit) {
    runCatching {
      callback(Result.success(sdk.isIdentified))
    }.onFailure { error ->
      callback(Result.failure(toFlutterError(error)))
    }
  }

  override fun startTrigger(request: PTriggerRequest, callback: (Result<Unit>) -> Unit) {
    val requestId = request.requestId
    val event = request.event

    if (requestId.isNullOrBlank()) {
      callback(Result.failure(FlutterError("INVALID_TRIGGER", "requestId is required", null)))
      return
    }
    if (event.isNullOrBlank()) {
      callback(Result.failure(FlutterError("INVALID_TRIGGER", "event is required", null)))
      return
    }

    runCatching {
      val handle = sdk.trigger(
        event = event,
        properties = request.properties.toStringKeyMap(),
        userProperties = request.userProperties.toStringKeyMap(),
        userPropertiesSetOnce = request.userPropertiesSetOnce.toStringKeyMap(),
      ) { update ->
        sendTriggerUpdate(requestId, update)
      }
      triggerHandles[requestId] = handle
      callback(Result.success(Unit))
    }.onFailure { error ->
      callback(Result.failure(toFlutterError(error)))
    }
  }

  override fun cancelTrigger(requestId: String, callback: (Result<Unit>) -> Unit) {
    runCatching {
      triggerHandles.remove(requestId)?.cancel()
      callback(Result.success(Unit))
    }.onFailure { error ->
      callback(Result.failure(toFlutterError(error)))
    }
  }

  override fun showFlow(flowId: String, callback: (Result<Unit>) -> Unit) {
    runCatching {
      sdk.showFlow(flowId)
      callback(Result.success(Unit))
    }.onFailure { error ->
      callback(Result.failure(toFlutterError(error)))
    }
  }

  override fun refreshProfile(callback: (Result<PProfileResponse>) -> Unit) {
    scope.launch {
      runCatching {
        val profile = sdk.refreshProfile()
        callback(Result.success(profile.toPProfileResponse()))
      }.onFailure { error ->
        callback(Result.failure(toFlutterError(error)))
      }
    }
  }

  override fun hasFeature(
    featureId: String,
    requiredBalance: Long?,
    entityId: String?,
    callback: (Result<PFeatureAccess>) -> Unit,
  ) {
    scope.launch {
      runCatching {
        val access = if (requiredBalance == null && entityId == null) {
          sdk.hasFeature(featureId)
        } else {
          sdk.hasFeature(featureId, requiredBalance?.toInt() ?: 1, entityId)
        }
        callback(Result.success(access.toPFeatureAccess()))
      }.onFailure { error ->
        callback(Result.failure(toFlutterError(error)))
      }
    }
  }

  override fun getCachedFeature(
    featureId: String,
    entityId: String?,
    callback: (Result<PFeatureAccess?>) -> Unit,
  ) {
    scope.launch {
      runCatching {
        val access = sdk.getCachedFeature(featureId, entityId)
        callback(Result.success(access?.toPFeatureAccess()))
      }.onFailure { error ->
        callback(Result.failure(toFlutterError(error)))
      }
    }
  }

  override fun checkFeature(
    featureId: String,
    requiredBalance: Long?,
    entityId: String?,
    callback: (Result<PFeatureCheckResult>) -> Unit,
  ) {
    scope.launch {
      runCatching {
        val result = sdk.checkFeature(featureId, requiredBalance?.toInt(), entityId)
        callback(Result.success(result.toPFeatureCheckResult()))
      }.onFailure { error ->
        callback(Result.failure(toFlutterError(error)))
      }
    }
  }

  override fun refreshFeature(
    featureId: String,
    requiredBalance: Long?,
    entityId: String?,
    callback: (Result<PFeatureCheckResult>) -> Unit,
  ) {
    scope.launch {
      runCatching {
        val result = sdk.refreshFeature(featureId, requiredBalance?.toInt(), entityId)
        callback(Result.success(result.toPFeatureCheckResult()))
      }.onFailure { error ->
        callback(Result.failure(toFlutterError(error)))
      }
    }
  }

  override fun useFeature(
    featureId: String,
    amount: Double,
    entityId: String?,
    metadata: Map<String?, Any?>?,
    callback: (Result<Unit>) -> Unit,
  ) {
    runCatching {
      sdk.useFeature(
        featureId = featureId,
        amount = amount,
        entityId = entityId,
        metadata = metadata.toStringKeyMap(),
      )
      callback(Result.success(Unit))
    }.onFailure { error ->
      callback(Result.failure(toFlutterError(error)))
    }
  }

  override fun useFeatureAndWait(
    featureId: String,
    amount: Double,
    entityId: String?,
    setUsage: Boolean,
    metadata: Map<String?, Any?>?,
    callback: (Result<PFeatureUsageResult>) -> Unit,
  ) {
    scope.launch {
      runCatching {
        val result = sdk.useFeatureAndWait(
          featureId = featureId,
          amount = amount,
          entityId = entityId,
          setUsage = setUsage,
          metadata = metadata.toStringKeyMap(),
        )
        callback(Result.success(result.toPFeatureUsageResult()))
      }.onFailure { error ->
        callback(Result.failure(toFlutterError(error)))
      }
    }
  }

  override fun flushEvents(callback: (Result<Boolean>) -> Unit) {
    scope.launch {
      runCatching {
        callback(Result.success(sdk.flushEvents()))
      }.onFailure { error ->
        callback(Result.failure(toFlutterError(error)))
      }
    }
  }

  override fun getQueuedEventCount(callback: (Result<Long>) -> Unit) {
    scope.launch {
      runCatching {
        callback(Result.success(sdk.getQueuedEventCount().toLong()))
      }.onFailure { error ->
        callback(Result.failure(toFlutterError(error)))
      }
    }
  }

  override fun pauseEventQueue(callback: (Result<Unit>) -> Unit) {
    scope.launch {
      runCatching {
        sdk.pauseEventQueue()
        callback(Result.success(Unit))
      }.onFailure { error ->
        callback(Result.failure(toFlutterError(error)))
      }
    }
  }

  override fun resumeEventQueue(callback: (Result<Unit>) -> Unit) {
    scope.launch {
      runCatching {
        sdk.resumeEventQueue()
        callback(Result.success(Unit))
      }.onFailure { error ->
        callback(Result.failure(toFlutterError(error)))
      }
    }
  }

  override fun completePurchase(
    requestId: String,
    result: PPurchaseResult,
    callback: (Result<Unit>) -> Unit,
  ) {
    val deferred = pendingPurchases.remove(requestId)
    if (deferred == null) {
      callback(
        Result.failure(
          FlutterError("PURCHASE_REQUEST_NOT_FOUND", "No pending purchase request for $requestId", null),
        ),
      )
      return
    }

    deferred.complete(result)
    callback(Result.success(Unit))
  }

  override fun completeRestore(
    requestId: String,
    result: PRestoreResult,
    callback: (Result<Unit>) -> Unit,
  ) {
    val deferred = pendingRestores.remove(requestId)
    if (deferred == null) {
      callback(
        Result.failure(
          FlutterError("RESTORE_REQUEST_NOT_FOUND", "No pending restore request for $requestId", null),
        ),
      )
      return
    }

    deferred.complete(result)
    callback(Result.success(Unit))
  }

  override fun featureAccessDidChange(featureId: String, from: FeatureAccess?, to: FeatureAccess) {
    flutterApi?.onFeatureAccessChanged(
      PFeatureAccessChangedEvent(
        featureId = featureId,
        from = from?.toPFeatureAccess(),
        to = to.toPFeatureAccess(),
        timestampMs = System.currentTimeMillis(),
      ),
    ) {
      // Ignore callback result.
    }
  }

  override fun flowDelegateCalled(
    message: String,
    payload: Any?,
    journeyId: String,
    campaignId: String?,
  ) {
    emitFlowLifecycle(
      type = "delegate_called",
      payload = mapOf(
        "message" to message,
        "payload" to payload,
        "journeyId" to journeyId,
        "campaignId" to campaignId,
      ),
    )
  }

  override fun flowPurchaseRequested(
    journeyId: String,
    campaignId: String?,
    screenId: String?,
    productId: String,
    placementIndex: Any?,
  ) {
    emitFlowLifecycle(
      type = "purchase_requested",
      payload = mapOf(
        "journeyId" to journeyId,
        "campaignId" to campaignId,
        "screenId" to screenId,
        "productId" to productId,
        "placementIndex" to placementIndex,
      ),
    )
  }

  override fun flowRestoreRequested(
    journeyId: String,
    campaignId: String?,
    screenId: String?,
  ) {
    emitFlowLifecycle(
      type = "restore_requested",
      payload = mapOf(
        "journeyId" to journeyId,
        "campaignId" to campaignId,
        "screenId" to screenId,
      ),
    )
  }

  override fun flowOpenLinkRequested(
    journeyId: String,
    campaignId: String?,
    screenId: String?,
    url: String,
    target: String?,
  ) {
    emitFlowLifecycle(
      type = "open_link_requested",
      payload = mapOf(
        "journeyId" to journeyId,
        "campaignId" to campaignId,
        "screenId" to screenId,
        "url" to url,
        "target" to target,
      ),
    )
  }

  override fun flowDismissed(
    journeyId: String,
    campaignId: String?,
    screenId: String?,
    reason: String,
    error: String?,
  ) {
    emitFlowLifecycle(
      type = "dismissed",
      reason = reason,
      payload = mapOf(
        "journeyId" to journeyId,
        "campaignId" to campaignId,
        "screenId" to screenId,
        "error" to error,
      ),
    )
  }

  override fun flowBackRequested(
    journeyId: String,
    campaignId: String?,
    screenId: String?,
    steps: Int,
  ) {
    emitFlowLifecycle(
      type = "back_requested",
      payload = mapOf(
        "journeyId" to journeyId,
        "campaignId" to campaignId,
        "screenId" to screenId,
        "steps" to steps,
      ),
    )
  }

  private fun sendTriggerUpdate(requestId: String, update: TriggerUpdate) {
    val event = update.toPTriggerUpdate(requestId)
    flutterApi?.onTriggerUpdate(event) {
      // Ignore callback result.
    }

    if (event.isTerminal == true) {
      triggerHandles.remove(requestId)
    }
  }

  private fun emitFlowLifecycle(
    type: String,
    flowId: String? = null,
    reason: String? = null,
    payload: Map<String, Any?> = emptyMap(),
  ) {
    flutterApi?.onFlowLifecycle(
      PFlowLifecycleEvent(
        type = type,
        flowId = flowId,
        reason = reason,
        timestampMs = System.currentTimeMillis(),
        payload = payload.toBridgeMap(),
      ),
    ) {
      // Ignore callback result.
    }
  }

  private fun buildConfiguration(apiKey: String, request: PConfigureRequest): NuxieConfiguration {
    val configuration = NuxieConfiguration(apiKey)

    request.environment?.let { configuration.environment = it.toEnvironment() }
    request.apiEndpoint?.takeIf { it.isNotBlank() }?.let { configuration.setApiEndpoint(it) }

    request.logLevel?.let { configuration.logLevel = it.toLogLevel() }
    request.enableConsoleLogging?.let { configuration.enableConsoleLogging = it }
    request.enableFileLogging?.let { configuration.enableFileLogging = it }
    request.redactSensitiveData?.let { configuration.redactSensitiveData = it }

    request.retryCount?.let { configuration.retryCount = it.toInt() }
    request.retryDelaySeconds?.let { configuration.retryDelaySeconds = it }
    request.eventBatchSize?.let { configuration.eventBatchSize = it.toInt() }
    request.flushAt?.let { configuration.flushAt = it.toInt() }
    request.flushIntervalSeconds?.let { configuration.flushIntervalSeconds = it }
    request.maxQueueSize?.let { configuration.maxQueueSize = it.toInt() }

    request.maxCacheSizeBytes?.let { configuration.maxCacheSizeBytes = it }
    request.cacheExpirationSeconds?.let { configuration.cacheExpirationSeconds = it }
    request.featureCacheTtlSeconds?.let { configuration.featureCacheTtlSeconds = it }
    request.localeIdentifier?.let { configuration.localeIdentifier = it }
    request.isDebugMode?.let { configuration.isDebugMode = it }
    request.eventLinkingPolicy?.let { configuration.eventLinkingPolicy = it.toEventLinkingPolicy() }

    request.maxFlowCacheSizeBytes?.let { configuration.maxFlowCacheSizeBytes = it }
    request.flowCacheExpirationSeconds?.let { configuration.flowCacheExpirationSeconds = it }
    request.maxConcurrentFlowDownloads?.let { configuration.maxConcurrentFlowDownloads = it.toInt() }
    request.flowDownloadTimeoutSeconds?.let { configuration.flowDownloadTimeoutSeconds = it }

    purchaseTimeoutMs = (request.purchaseTimeoutSeconds ?: 60L) * 1000L

    return configuration
  }

  private fun toFlutterError(error: Throwable): Throwable {
    if (error is FlutterError) {
      return error
    }
    return FlutterError("NATIVE_ERROR", error.message ?: error.toString(), null)
  }

  private fun cleanupPendingRequests() {
    for ((_, deferred) in pendingPurchases) {
      if (deferred.isActive) {
        deferred.complete(PPurchaseResult(type = "failed", message = "sdk_shutdown"))
      }
    }
    pendingPurchases.clear()

    for ((_, deferred) in pendingRestores) {
      if (deferred.isActive) {
        deferred.complete(PRestoreResult(type = "failed", message = "sdk_shutdown"))
      }
    }
    pendingRestores.clear()

    for ((_, handle) in triggerHandles) {
      handle.cancel()
    }
    triggerHandles.clear()
  }

  private fun nextRequestId(prefix: String): String {
    return "$prefix-${System.currentTimeMillis()}-${requestCounter.incrementAndGet()}-${UUID.randomUUID()}"
  }

  private inner class FlutterPurchaseDelegate(
    private val plugin: NuxieFlutterNativePlugin,
  ) : NuxiePurchaseDelegate {

    override suspend fun purchase(productId: String): PurchaseResult {
      return purchaseOutcome(productId).result
    }

    override suspend fun purchaseOutcome(productId: String): PurchaseOutcome {
      val requestId = nextRequestId("purchase")
      val deferred = CompletableDeferred<PPurchaseResult>()
      pendingPurchases[requestId] = deferred

      val request = PPurchaseRequest(
        requestId = requestId,
        platform = "android",
        productId = productId,
        timestampMs = System.currentTimeMillis(),
      )

      withContext(Dispatchers.Main.immediate) {
        flutterApi?.onPurchaseRequest(request) {
          // Ignore callback result.
        }
      }

      val response = try {
        withTimeout(purchaseTimeoutMs) { deferred.await() }
      } catch (_: Throwable) {
        PPurchaseResult(type = "failed", message = "purchase_timeout")
      } finally {
        pendingPurchases.remove(requestId)
      }

      return response.toPurchaseOutcome(productId)
    }

    override suspend fun restore(): RestoreResult {
      val requestId = nextRequestId("restore")
      val deferred = CompletableDeferred<PRestoreResult>()
      pendingRestores[requestId] = deferred

      val request = PRestoreRequest(
        requestId = requestId,
        platform = "android",
        timestampMs = System.currentTimeMillis(),
      )

      withContext(Dispatchers.Main.immediate) {
        flutterApi?.onRestoreRequest(request) {
          // Ignore callback result.
        }
      }

      val response = try {
        withTimeout(purchaseTimeoutMs) { deferred.await() }
      } catch (_: Throwable) {
        PRestoreResult(type = "failed", message = "restore_timeout")
      } finally {
        pendingRestores.remove(requestId)
      }

      return response.toRestoreResult()
    }
  }

  private class NuxieFlowViewFactory(
    private val plugin: NuxieFlutterNativePlugin,
  ) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
      val flowId = (args as? Map<*, *>)?.get("flowId") as? String
      return NuxieFlowPlatformView(context, plugin, flowId)
    }
  }

  private class NuxieFlowPlatformView(
    context: Context,
    private val plugin: NuxieFlutterNativePlugin,
    flowId: String?,
  ) : PlatformView {
    private val container = FrameLayout(context)

    init {
      if (!flowId.isNullOrBlank()) {
        val activity = plugin.activity
        if (activity != null) {
          plugin.scope.launch {
            runCatching {
              val flowView = plugin.sdk.getFlowView(activity, flowId)
              withContext(Dispatchers.Main.immediate) {
                container.removeAllViews()
                container.addView(
                  flowView,
                  FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT,
                  ),
                )
              }
            }.onFailure {
              // Ignore load failures; host can still present via showFlow.
            }
          }
        }
      }
    }

    override fun getView(): View = container

    override fun dispose() {
      container.removeAllViews()
    }
  }
}

private fun String.toEnvironment(): Environment {
  return when (lowercase()) {
    "staging" -> Environment.STAGING
    "development" -> Environment.DEVELOPMENT
    "custom" -> Environment.CUSTOM
    else -> Environment.PRODUCTION
  }
}

private fun String.toLogLevel(): LogLevel {
  return when (lowercase()) {
    "verbose" -> LogLevel.VERBOSE
    "debug" -> LogLevel.DEBUG
    "info" -> LogLevel.INFO
    "warning" -> LogLevel.WARNING
    "error" -> LogLevel.ERROR
    "none" -> LogLevel.NONE
    else -> LogLevel.WARNING
  }
}

private fun String.toEventLinkingPolicy(): EventLinkingPolicy {
  return when (lowercase()) {
    "keep_separate" -> EventLinkingPolicy.KEEP_SEPARATE
    "migrate_on_identify" -> EventLinkingPolicy.MIGRATE_ON_IDENTIFY
    else -> EventLinkingPolicy.MIGRATE_ON_IDENTIFY
  }
}

private fun Map<String?, Any?>?.toStringKeyMap(): Map<String, Any?>? {
  if (this == null) {
    return null
  }
  return buildMap {
    for ((key, value) in this@toStringKeyMap) {
      if (!key.isNullOrBlank()) {
        put(key, value)
      }
    }
  }
}

private fun Map<String, Any?>.toBridgeMap(): Map<String?, Any?> {
  return mapValues { (_, value) -> value.toBridgeValue() }
}

private fun Any?.toBridgeValue(): Any? {
  return when (this) {
    null -> null
    is String, is Boolean, is Number -> this
    is Map<*, *> -> {
      buildMap<String?, Any?> {
        for ((key, value) in this@toBridgeValue) {
          put(key?.toString(), value.toBridgeValue())
        }
      }
    }
    is Iterable<*> -> this.map { it.toBridgeValue() }
    else -> this.toString()
  }
}

private fun TriggerUpdate.toPTriggerUpdate(requestId: String): PTriggerUpdate {
  val timestamp = System.currentTimeMillis()

  return when (this) {
    is TriggerUpdate.Decision -> {
      val payload = decision.toDecisionPayload()
      PTriggerUpdate(
        requestId = requestId,
        updateKind = "decision",
        payload = payload,
        isTerminal = isTerminalDecision(decision),
        timestampMs = timestamp,
      )
    }
    is TriggerUpdate.Entitlement -> {
      val payload = entitlement.toEntitlementPayload()
      PTriggerUpdate(
        requestId = requestId,
        updateKind = "entitlement",
        payload = payload,
        isTerminal = isTerminalEntitlement(entitlement),
        timestampMs = timestamp,
      )
    }
    is TriggerUpdate.Journey -> {
      val payload = journey.toJourneyPayload()
      PTriggerUpdate(
        requestId = requestId,
        updateKind = "journey",
        payload = payload,
        isTerminal = true,
        timestampMs = timestamp,
      )
    }
    is TriggerUpdate.Error -> {
      val payload = error.toErrorPayload()
      PTriggerUpdate(
        requestId = requestId,
        updateKind = "error",
        payload = payload,
        isTerminal = true,
        timestampMs = timestamp,
      )
    }
  }
}

private fun TriggerDecision.toDecisionPayload(): Map<String?, Any?> {
  return when (this) {
    TriggerDecision.NoMatch -> mapOf("type" to "no_match")
    is TriggerDecision.Suppressed -> mapOf(
      "type" to "suppressed",
      "reason" to reason.toBridgeReason(),
    )
    is TriggerDecision.JourneyStarted -> mapOf(
      "type" to "journey_started",
      "ref" to ref.toBridgeRef(),
    )
    is TriggerDecision.JourneyResumed -> mapOf(
      "type" to "journey_resumed",
      "ref" to ref.toBridgeRef(),
    )
    is TriggerDecision.FlowShown -> mapOf(
      "type" to "flow_shown",
      "ref" to ref.toBridgeRef(),
    )
    TriggerDecision.AllowedImmediate -> mapOf("type" to "allowed_immediate")
    TriggerDecision.DeniedImmediate -> mapOf("type" to "denied_immediate")
  }
}

private fun TriggerDecision.toBridgeReason(): String {
  return when (this) {
    is TriggerDecision.Suppressed -> reason.toBridgeReason()
    else -> "unknown"
  }
}

private fun SuppressReason.toBridgeReason(): String {
  return when (this) {
    SuppressReason.AlreadyActive -> "already_active"
    SuppressReason.ReentryLimited -> "reentry_limited"
    SuppressReason.Holdout -> "holdout"
    SuppressReason.NoFlow -> "no_flow"
    is SuppressReason.Unknown -> "unknown"
  }
}

private fun EntitlementUpdate.toEntitlementPayload(): Map<String?, Any?> {
  return when (this) {
    EntitlementUpdate.Pending -> mapOf("type" to "pending")
    is EntitlementUpdate.Allowed -> mapOf(
      "type" to "allowed",
      "source" to source.toBridgeSource(),
    )
    EntitlementUpdate.Denied -> mapOf("type" to "denied")
  }
}

private fun GateSource.toBridgeSource(): String {
  return when (this) {
    GateSource.CACHE -> "cache"
    GateSource.PURCHASE -> "purchase"
    GateSource.RESTORE -> "restore"
  }
}

private fun JourneyRef.toBridgeRef(): Map<String?, Any?> {
  return mapOf(
    "journeyId" to journeyId,
    "campaignId" to campaignId,
    "flowId" to flowId,
  )
}

private fun JourneyUpdate.toJourneyPayload(): Map<String?, Any?> {
  return mapOf(
    "journeyId" to journeyId,
    "campaignId" to campaignId,
    "flowId" to flowId,
    "exitReason" to exitReason.toBridgeExitReason(),
    "goalMet" to goalMet,
    "goalMetAtEpochMillis" to goalMetAtEpochMillis,
    "durationSeconds" to durationSeconds,
    "flowExitReason" to flowExitReason,
  )
}

private fun JourneyExitReason.toBridgeExitReason(): String {
  return when (this) {
    JourneyExitReason.COMPLETED -> "completed"
    JourneyExitReason.GOAL_MET -> "goal_met"
    JourneyExitReason.TRIGGER_UNMATCHED -> "trigger_unmatched"
    JourneyExitReason.EXPIRED -> "expired"
    JourneyExitReason.ERROR -> "error"
    JourneyExitReason.CANCELLED -> "cancelled"
  }
}

private fun TriggerError.toErrorPayload(): Map<String?, Any?> {
  return mapOf(
    "code" to code,
    "message" to message,
  )
}

private fun isTerminalDecision(decision: TriggerDecision): Boolean {
  return when (decision) {
    TriggerDecision.AllowedImmediate,
    TriggerDecision.DeniedImmediate,
    TriggerDecision.NoMatch,
    is TriggerDecision.Suppressed,
    -> true
    is TriggerDecision.FlowShown,
    is TriggerDecision.JourneyResumed,
    is TriggerDecision.JourneyStarted,
    -> false
  }
}

private fun isTerminalEntitlement(update: EntitlementUpdate): Boolean {
  return when (update) {
    is EntitlementUpdate.Allowed,
    EntitlementUpdate.Denied,
    -> true
    EntitlementUpdate.Pending -> false
  }
}

private fun ProfileResponse.toPProfileResponse(): PProfileResponse {
  val element = Json.encodeToJsonElement(ProfileResponse.serializer(), this)
  return PProfileResponse(raw = element.toBridgeMap())
}

private fun FeatureAccess.toPFeatureAccess(): PFeatureAccess {
  return PFeatureAccess(
    allowed = allowed,
    unlimited = unlimited,
    balance = balance?.toLong(),
    type = type.toBridgeType(),
  )
}

private fun FeatureCheckResult.toPFeatureCheckResult(): PFeatureCheckResult {
  return PFeatureCheckResult(
    customerId = customerId,
    featureId = featureId,
    requiredBalance = requiredBalance.toLong(),
    code = code,
    allowed = allowed,
    unlimited = unlimited,
    balance = balance?.toLong(),
    type = type.toBridgeType(),
    preview = preview?.toBridgeValue(),
  )
}

private fun FeatureUsageResult.toPFeatureUsageResult(): PFeatureUsageResult {
  return PFeatureUsageResult(
    success = success,
    featureId = featureId,
    amountUsed = amountUsed,
    message = message,
    usageCurrent = usage?.current,
    usageLimit = usage?.limit,
    usageRemaining = usage?.remaining,
  )
}

private fun FeatureType.toBridgeType(): String {
  return when (this) {
    FeatureType.BOOLEAN -> "boolean"
    FeatureType.METERED -> "metered"
    FeatureType.CREDIT_SYSTEM -> "creditSystem"
  }
}

private fun PPurchaseResult.toPurchaseOutcome(defaultProductId: String): PurchaseOutcome {
  val resolvedProductId = productId ?: defaultProductId

  val purchaseResult = when (type) {
    "success" -> PurchaseResult.Success
    "cancelled" -> PurchaseResult.Cancelled
    "pending" -> PurchaseResult.Pending
    else -> PurchaseResult.Failed(message ?: "purchase_failed")
  }

  return PurchaseOutcome(
    result = purchaseResult,
    productId = resolvedProductId,
    purchaseToken = purchaseToken,
    orderId = orderId,
  )
}

private fun PRestoreResult.toRestoreResult(): RestoreResult {
  return when (type) {
    "success" -> RestoreResult.Success(restoredCount ?: 0)
    "no_purchases" -> RestoreResult.NoPurchases
    else -> RestoreResult.Failed(message ?: "restore_failed")
  }
}

private fun JsonElement.toBridgeValue(): Any? {
  return when (this) {
    JsonNull -> null
    is JsonPrimitive -> {
      booleanOrNull ?: longOrNull ?: doubleOrNull ?: content
    }
    is JsonArray -> this.map { it.toBridgeValue() }
    is JsonObject -> this.toBridgeMap()
  }
}

private fun JsonObject.toBridgeMap(): Map<String?, Any?> {
  return entries.associate { (key, value) ->
    key to value.toBridgeValue()
  }
}
