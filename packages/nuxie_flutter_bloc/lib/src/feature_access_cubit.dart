import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:nuxie_flutter/nuxie_flutter.dart';

class FeatureAccessCubit extends Cubit<FeatureAccess?> {
  FeatureAccessCubit(this._nuxie, this._featureId) : super(null) {
    _subscription = _nuxie.featureAccessChanges.listen((event) {
      if (event.featureId == _featureId) {
        emit(event.to);
      }
    });
  }

  final Nuxie _nuxie;
  final String _featureId;
  StreamSubscription<FeatureAccessChangedEvent>? _subscription;

  Future<void> refresh() async {
    final result = await _nuxie.platform.hasFeature(_featureId);
    emit(result);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
