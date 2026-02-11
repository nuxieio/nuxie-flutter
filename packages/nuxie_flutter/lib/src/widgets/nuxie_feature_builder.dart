import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:nuxie_flutter_platform_interface/nuxie_flutter_platform_interface.dart';

import '../core/nuxie.dart';

typedef NuxieFeatureWidgetBuilder = Widget Function(
  BuildContext context,
  FeatureAccess? access,
  bool isLoading,
  Object? error,
);

/// Convenience widget for rendering feature access state reactively.
class NuxieFeatureBuilder extends StatefulWidget {
  const NuxieFeatureBuilder({
    super.key,
    required this.featureId,
    required this.builder,
    this.requiredBalance,
    this.entityId,
    this.autoRefresh = true,
  });

  final String featureId;
  final int? requiredBalance;
  final String? entityId;
  final bool autoRefresh;
  final NuxieFeatureWidgetBuilder builder;

  @override
  State<NuxieFeatureBuilder> createState() =>
      _NuxieFeatureBuilderWidgetState();
}

class _NuxieFeatureBuilderWidgetState extends State<NuxieFeatureBuilder> {
  StreamSubscription<FeatureAccessChangedEvent>? _subscription;
  FeatureAccess? _access;
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();

    final nuxie = Nuxie.instance;
    _subscription = nuxie.featureAccessChanges.listen((event) {
      if (event.featureId != widget.featureId) {
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _access = event.to;
        _error = null;
        _isLoading = false;
      });
    });

    if (widget.autoRefresh) {
      unawaited(_refresh());
    } else {
      _isLoading = false;
    }
  }

  @override
  void didUpdateWidget(covariant NuxieFeatureBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.featureId != widget.featureId ||
        oldWidget.requiredBalance != widget.requiredBalance ||
        oldWidget.entityId != widget.entityId) {
      unawaited(_refresh());
    }
  }

  Future<void> _refresh() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final access = await Nuxie.instance.hasFeature(
        widget.featureId,
        requiredBalance: widget.requiredBalance,
        entityId: widget.entityId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _access = access;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _access, _isLoading, _error);
  }
}
