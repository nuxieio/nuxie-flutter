import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Embedded native flow surface.
///
/// Requires `Nuxie.initialize(...)` to be called first.
class NuxieFlowView extends StatelessWidget {
  const NuxieFlowView({
    super.key,
    required this.flowId,
    this.gestureRecognizers,
    this.hitTestBehavior = PlatformViewHitTestBehavior.opaque,
    this.placeholder,
  });

  final String flowId;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final PlatformViewHitTestBehavior hitTestBehavior;
  final Widget? placeholder;

  static const String viewType = 'io.nuxie.flutter.native/flow_view';

  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidView(
          viewType: viewType,
          creationParams: <String, Object?>{'flowId': flowId},
          creationParamsCodec: const StandardMessageCodec(),
          gestureRecognizers: gestureRecognizers,
          hitTestBehavior: hitTestBehavior,
        );
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: viewType,
          creationParams: <String, Object?>{'flowId': flowId},
          creationParamsCodec: const StandardMessageCodec(),
          gestureRecognizers: gestureRecognizers,
          hitTestBehavior: hitTestBehavior,
        );
      default:
        return placeholder ??
            const Center(
              child: Text('NuxieFlowView is only supported on iOS and Android.'),
            );
    }
  }
}
