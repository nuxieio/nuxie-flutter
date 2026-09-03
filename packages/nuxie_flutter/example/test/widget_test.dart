import 'package:flutter_test/flutter_test.dart';

import 'package:nuxie_flutter_example/main.dart';

void main() {
  testWidgets('example exposes event-driven Journey controls', (tester) async {
    await tester.pumpWidget(const NuxieExampleApp(initializeSdk: false));

    expect(find.text('Nuxie Flutter Example'), findsOneWidget);
    expect(find.text('Capture Event'), findsOneWidget);
    expect(find.text('Load Feature'), findsOneWidget);
  });
}
