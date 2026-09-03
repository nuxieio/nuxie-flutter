import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:nuxie_flutter/nuxie_flutter.dart';

class FeatureAccessCubit extends Cubit<FeatureAccess?> {
  FeatureAccessCubit(
    this._nuxie,
    this._featureId, {
    this.requiredBalance,
    this.entityId,
    this.policy = FeatureCheckPolicy.cacheFirst,
    this.autoRefresh = true,
  }) : super(null) {
    _subscription = _nuxie.featureAccessChanges.listen((event) {
      if (event.featureId == _featureId) {
        emit(event.to);
      }
    });

    if (autoRefresh) {
      unawaited(refresh());
    }
  }

  final Nuxie _nuxie;
  final String _featureId;
  final double? requiredBalance;
  final String? entityId;
  final FeatureCheckPolicy policy;
  final bool autoRefresh;

  StreamSubscription<FeatureAccessChangedEvent>? _subscription;

  Future<void> refresh() async {
    final result = await _nuxie.hasFeature(
      _featureId,
      requiredBalance: requiredBalance ?? 1,
      entityId: entityId,
      policy: policy,
    );
    emit(result);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
