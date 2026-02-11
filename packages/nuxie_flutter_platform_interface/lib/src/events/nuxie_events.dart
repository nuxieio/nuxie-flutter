import '../models/feature_models.dart';
import '../models/trigger_models.dart';

class FeatureAccessChangedEvent {
  const FeatureAccessChangedEvent({
    required this.featureId,
    required this.to,
    this.from,
    this.timestampMs,
  });

  final String featureId;
  final FeatureAccess? from;
  final FeatureAccess to;
  final int? timestampMs;
}

class NuxieTriggerUpdateEvent {
  const NuxieTriggerUpdateEvent({
    required this.requestId,
    required this.update,
    required this.isTerminal,
    required this.timestampMs,
  });

  final String requestId;
  final TriggerUpdate update;
  final bool isTerminal;
  final int timestampMs;
}

class NuxieFlowLifecycleEvent {
  const NuxieFlowLifecycleEvent({
    required this.type,
    this.flowId,
    this.reason,
    this.timestampMs,
    this.payload,
  });

  final String type;
  final String? flowId;
  final String? reason;
  final int? timestampMs;
  final Map<String, Object?>? payload;
}

class NuxieLogEvent {
  const NuxieLogEvent({
    required this.level,
    required this.message,
    this.scope,
    this.timestampMs,
  });

  final String level;
  final String message;
  final String? scope;
  final int? timestampMs;
}
