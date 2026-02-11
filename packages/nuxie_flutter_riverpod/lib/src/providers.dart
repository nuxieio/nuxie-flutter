import 'package:nuxie_flutter/nuxie_flutter.dart';
import 'package:riverpod/riverpod.dart';

final nuxieProvider = Provider<Nuxie>((_) => Nuxie.instance);

class NuxieFeatureQuery {
  const NuxieFeatureQuery(
    this.featureId, {
    this.requiredBalance,
    this.entityId,
  });

  final String featureId;
  final int? requiredBalance;
  final String? entityId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is NuxieFeatureQuery &&
        other.featureId == featureId &&
        other.requiredBalance == requiredBalance &&
        other.entityId == entityId;
  }

  @override
  int get hashCode => Object.hash(featureId, requiredBalance, entityId);
}

final nuxieFeatureProvider =
    StreamProvider.autoDispose.family<FeatureAccess?, NuxieFeatureQuery>(
  (ref, query) async* {
    final nuxie = ref.watch(nuxieProvider);

    final initial = await nuxie.hasFeature(
      query.featureId,
      requiredBalance: query.requiredBalance,
      entityId: query.entityId,
    );
    yield initial;

    yield* nuxie.featureAccessChanges
        .where((event) => event.featureId == query.featureId)
        .map((event) => event.to);
  },
);
