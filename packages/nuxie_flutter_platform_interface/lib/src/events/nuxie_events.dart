import '../models/feature_models.dart';

class FeatureAccessChangedEvent {
  const FeatureAccessChangedEvent({
    required this.featureId,
    required this.to,
    required this.timestampMs,
    this.from,
  });

  final String featureId;
  final FeatureAccess? from;
  final FeatureAccess to;
  final int timestampMs;
}
