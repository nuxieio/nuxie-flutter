import 'package:flutter/widgets.dart';

import '../core/nuxie.dart';

typedef NuxieWidgetBuilder = Widget Function(BuildContext context, Nuxie nuxie);

/// Lightweight convenience widget for accessing the configured Nuxie singleton.
class NuxieBuilder extends StatelessWidget {
  const NuxieBuilder({
    super.key,
    required this.builder,
    this.unconfiguredBuilder,
  });

  final NuxieWidgetBuilder builder;
  final WidgetBuilder? unconfiguredBuilder;

  @override
  Widget build(BuildContext context) {
    try {
      return builder(context, Nuxie.instance);
    } catch (_) {
      final fallback = unconfiguredBuilder;
      if (fallback != null) {
        return fallback(context);
      }
      return const SizedBox.shrink();
    }
  }
}
